terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.6.0"
    }
  }
}

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

resource "random_id" "default" {
  byte_length = 8
}

resource "google_pubsub_topic" "req_to_func2" {
  count = var.num_workers
  name  = "${var.prefix}-req-to-func2-${count.index}"
}

resource "google_storage_bucket" "gcf_source" {
  name                        = "${var.prefix}-gcf-source-${random_id.default.hex}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket" "result_data" {
  name                        = "${var.prefix}-result-data-${random_id.default.hex}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

# Function 1

locals {
  function1_name = "${var.prefix}-func1"
}

data "archive_file" "func1_source" {
  type        = "zip"
  source_dir  = "./src"
  output_path = "./src_zip/${local.function1_name}-source.zip"
}

resource "google_storage_bucket_object" "func1_archive" {
  name   = "${local.function1_name}-source-${data.archive_file.func1_source.output_md5}.zip"
  bucket = google_storage_bucket.gcf_source.name
  source = data.archive_file.func1_source.output_path
}

resource "google_cloudfunctions2_function" "func1" {
  name     = local.function1_name
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "main"
    environment_variables = {
      GOOGLE_FUNCTION_SOURCE = "func1.py"
    }
    source {
      storage_source {
        bucket = google_storage_bucket.gcf_source.name
        object = google_storage_bucket_object.func1_archive.name
      }
    }
  }

  service_config {
    service_account_email = google_service_account.function.email
    min_instance_count    = 0
    max_instance_count    = 1
    available_memory      = "256M"
    timeout_seconds       = 60
    environment_variables = {
      PROJECT_ID         = var.project_id
      NUM_WORKERS        = var.num_workers
      REQ_TO_FUNC2_TOPIC = "${var.prefix}-req-to-func2"
    }
  }
}

# Function 2

locals {
  function2_name = "${var.prefix}-func2"
}

data "archive_file" "func2_source" {
  type        = "zip"
  source_dir  = "./src"
  output_path = "./src_zip/${local.function2_name}-source.zip"
}

resource "google_storage_bucket_object" "func2_archive" {
  name   = "${local.function2_name}-source-${data.archive_file.func2_source.output_md5}.zip"
  bucket = google_storage_bucket.gcf_source.name
  source = data.archive_file.func2_source.output_path
}

resource "google_cloudfunctions2_function" "func2" {
  count = var.num_workers

  name     = "${local.function2_name}-${count.index}"
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "main"
    environment_variables = {
      GOOGLE_FUNCTION_SOURCE = "func2.py"
    }
    source {
      storage_source {
        bucket = google_storage_bucket.gcf_source.name
        object = google_storage_bucket_object.func2_archive.name
      }
    }
  }

  service_config {
    service_account_email            = google_service_account.function.email
    min_instance_count               = 0
    max_instance_count               = 1
    max_instance_request_concurrency = 1
    available_cpu                    = "1"
    available_memory                 = "256M"
    timeout_seconds                  = 60
    environment_variables = {
      RESULT_BUCKET_NAME = google_storage_bucket.result_data.name
      FUNC_NAME          = "${local.function2_name}-${count.index}"
    }
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.req_to_func2[count.index].id
    service_account_email = google_service_account.pubsub.email
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
  }
}

output "function_name" {
  value = google_cloudfunctions2_function.func1.name
}

# triggerがfunc2を起動するために、Cloud Run 起動元の権限を付与
resource "google_cloud_run_service_iam_member" "function_invoker" {
  count    = var.num_workers
  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.func2[count.index].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub.email}"
}

# func1がPub/Subメッセージを送信するために、Pub/Sub パブリッシャーの権限を付与
resource "google_pubsub_topic_iam_member" "publisher" {
  count  = var.num_workers
  topic  = google_pubsub_topic.req_to_func2[count.index].name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.function.email}"
}

# func2がストレージにファイルを書き込むために、Storage オブジェクト作成者の権限を付与
resource "google_storage_bucket_iam_member" "writer" {
  bucket = google_storage_bucket.result_data.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.function.email}"
}
