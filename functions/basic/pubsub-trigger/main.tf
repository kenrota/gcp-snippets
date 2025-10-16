terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
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

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "google_storage_bucket" "gcf_source" {
  name                        = "${var.prefix}-gcf-source-${random_id.bucket_suffix.hex}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket" "idempotency_markers" {
  name                        = "${var.prefix}-idempotency-markers-${random_id.bucket_suffix.hex}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_pubsub_topic" "req_to_func" {
  name = "${var.prefix}-req-to-func"
}

resource "google_cloud_scheduler_job" "trigger_func" {
  name      = "${var.prefix}-trigger-func"
  schedule  = "*/1 * * * *"
  time_zone = "Asia/Tokyo"

  pubsub_target {
    topic_name = google_pubsub_topic.req_to_func.id
    data       = base64encode("test")
  }

  retry_config {
    retry_count = 0
  }
}

locals {
  function_name = "${var.prefix}-cloud-event"
}

# アーカイブのハッシュ値の使い方は以下のIssueを参考にした。
# https://github.com/hashicorp/terraform-provider-google/issues/1938

data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "./src"
  output_path = "/tmp/${local.function_name}-source.zip"
}

resource "google_storage_bucket_object" "function_archive" {
  name   = "${local.function_name}-source-${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.gcf_source.name
  source = data.archive_file.function_source.output_path
}

resource "google_cloudfunctions2_function" "cloud_event" {
  name     = local.function_name
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
        object = google_storage_bucket_object.function_archive.name
      }
    }
  }

  service_config {
    min_instance_count    = 0
    max_instance_count    = 1
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.function.email
    environment_variables = {
      IDEMPOTENCY_BUCKET = google_storage_bucket.idempotency_markers.name
    }
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.req_to_func.id
    service_account_email = google_service_account.pubsub.email
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
  }
}

resource "google_cloud_run_service_iam_member" "function_invoker" {
  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.cloud_event.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub.email}"
}

resource "google_storage_bucket_iam_member" "writer" {
  bucket = google_storage_bucket.idempotency_markers.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.function.email}"
}
