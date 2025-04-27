provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "function" {
  account_id = "${var.prefix}-function"
}

resource "google_service_account" "pubsub" {
  account_id = "${var.prefix}-pubsub"
}

# Pub/Sub

resource "google_pubsub_topic" "main" {
  name = "${var.prefix}-main"
}

resource "google_pubsub_topic" "dead_letter" {
  name = "${var.prefix}-dead-letter"
}

resource "google_pubsub_subscription" "main" {
  name  = "${var.prefix}-main"
  topic = google_pubsub_topic.main.id

  push_config {
    push_endpoint = google_cloudfunctions2_function.main.service_config[0].uri

    oidc_token {
      service_account_email = google_service_account.pubsub.email
    }
  }

  retry_policy {
    minimum_backoff = "60s"
  }

  dead_letter_policy {
    # 注意: もしデッドレター・トピックのサブスクリプションがない場合はメッセージは削除されないため、
    # 指定回数の試行後に再びメイン関数へメッセージが送信される。
    # そのため、デッドレター・トピックとメイン・トピック間のメッセージ送信が繰り返される。

    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5 # 指定した回数の試行後にデッドレター・トピックにメッセージが送信される。
  }

  depends_on = [
    google_cloudfunctions2_function.main,
    google_pubsub_topic.main,
    google_pubsub_topic.dead_letter,
  ]
}

# Storage

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "google_storage_bucket" "gcf_source" {
  name                        = "${var.prefix}-gcf-source-${random_id.bucket_suffix.hex}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

# メイン関数

locals {
  func_main = "${var.prefix}-main"
}

data "archive_file" "func_main" {
  type        = "zip"
  source_dir  = "./src"
  excludes    = ["dl_receiver.py"]
  output_path = "/tmp/${local.func_main}-source.zip"
}

resource "google_storage_bucket_object" "func_main" {
  name   = "${local.func_main}-source-${data.archive_file.func_main.output_md5}.zip"
  bucket = google_storage_bucket.gcf_source.name
  source = data.archive_file.func_main.output_path
}

resource "google_cloudfunctions2_function" "main" {
  name     = local.func_main
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "main"
    environment_variables = {
      GOOGLE_FUNCTION_SOURCE = "main.py"
    }
    source {
      storage_source {
        bucket = google_storage_bucket.gcf_source.name
        object = google_storage_bucket_object.func_main.name
      }
    }
  }

  service_config {
    min_instance_count    = 0
    max_instance_count    = 1
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.function.email
  }

  depends_on = [
    google_storage_bucket_object.func_main,
    google_storage_bucket.gcf_source
  ]
}

# デッドレター用関数

locals {
  func_dl_receiver = "${var.prefix}-dl-receiver"
}

data "archive_file" "func_dl_receiver" {
  type        = "zip"
  source_dir  = "./src"
  excludes    = ["main.py"]
  output_path = "/tmp/${local.func_dl_receiver}-source.zip"
}

resource "google_storage_bucket_object" "func_dl_receiver" {
  name   = "${local.func_dl_receiver}-source-${data.archive_file.func_dl_receiver.output_md5}.zip"
  bucket = google_storage_bucket.gcf_source.name
  source = data.archive_file.func_dl_receiver.output_path
}

resource "google_cloudfunctions2_function" "dl_receiver" {
  name     = local.func_dl_receiver
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "main"
    environment_variables = {
      GOOGLE_FUNCTION_SOURCE = "dl_receiver.py"
    }
    source {
      storage_source {
        bucket = google_storage_bucket.gcf_source.name
        object = google_storage_bucket_object.func_dl_receiver.name
      }
    }
  }

  service_config {
    min_instance_count    = 0
    max_instance_count    = 1
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.function.email
  }

  # event_trigger で指定したトピックのサブスクリプションは自動で作成される。
  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.dead_letter.id
    service_account_email = google_service_account.pubsub.email
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
  }

  depends_on = [
    google_storage_bucket_object.func_dl_receiver,
    google_storage_bucket.gcf_source
  ]
}

resource "google_cloud_run_service_iam_member" "function_invoker" {
  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.main.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub.email}"
}
