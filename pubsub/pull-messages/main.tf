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

resource "google_pubsub_topic" "req_fetcher" {
  name = "${var.prefix}-req-fetcher"
}

resource "google_pubsub_topic" "buffer" {
  name = "${var.prefix}-buffer"
}

resource "google_pubsub_subscription" "buffer" {
  name  = "${var.prefix}-buffer"
  topic = google_pubsub_topic.buffer.id
}

# Scheduler

resource "google_cloud_scheduler_job" "trigger_fetcher" {
  name      = "${var.prefix}-trigger-fetcher"
  schedule  = "*/1 * * * *"
  time_zone = "Asia/Tokyo"

  pubsub_target {
    topic_name = google_pubsub_topic.req_fetcher.id
    data       = base64encode("test")
  }

  retry_config {
    retry_count = 0
  }
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

# バッファされたデータの取得関数

locals {
  func_fetcher = "${var.prefix}-fetcher"
}

data "archive_file" "func_fetcher" {
  type        = "zip"
  source_dir  = "./src"
  output_path = "/tmp/${local.func_fetcher}-source.zip"
}

resource "google_storage_bucket_object" "func_fetcher" {
  name   = "${local.func_fetcher}-source-${data.archive_file.func_fetcher.output_md5}.zip"
  bucket = google_storage_bucket.gcf_source.name
  source = data.archive_file.func_fetcher.output_path
}

resource "google_cloudfunctions2_function" "fetcher" {
  name     = local.func_fetcher
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "main"
    environment_variables = {
      GOOGLE_FUNCTION_SOURCE = "fetcher.py"
    }
    source {
      storage_source {
        bucket = google_storage_bucket.gcf_source.name
        object = google_storage_bucket_object.func_fetcher.name
      }
    }
  }

  service_config {
    min_instance_count    = 0
    max_instance_count    = 1
    available_cpu         = "1"
    available_memory      = "1Gi"
    timeout_seconds       = 60
    service_account_email = google_service_account.function.email
    environment_variables = {
      PROJECT_ID               = var.project_id
      BUFFER_SUBSCRIPTION_NAME = google_pubsub_subscription.buffer.name
    }
  }

  # event_trigger で指定したトピックのサブスクリプションは自動で作成される。
  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.req_fetcher.id
    service_account_email = google_service_account.pubsub.email
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
  }

  depends_on = [
    google_storage_bucket_object.func_fetcher,
    google_storage_bucket.gcf_source
  ]
}

resource "google_pubsub_subscription_iam_member" "subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.buffer.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.function.email}"
}

resource "google_cloud_run_service_iam_member" "function_invoker" {
  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.fetcher.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub.email}"
}
