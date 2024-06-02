provider "google" {
  project = var.project_id
  region  = var.region
}

# Pub/Sub

resource "google_pubsub_topic" "req_poller" {
  name = "${var.prefix}-req-poller"
}

resource "google_pubsub_topic" "queue" {
  name = "${var.prefix}-queue"
}

resource "google_pubsub_subscription" "queue" {
  name  = "${var.prefix}-queue"
  topic = google_pubsub_topic.queue.id
}

# Scheduler

resource "google_cloud_scheduler_job" "trigger_poller" {
  name      = "${var.prefix}-trigger-poller"
  schedule  = "*/1 * * * *"
  time_zone = "Asia/Tokyo"

  pubsub_target {
    topic_name = google_pubsub_topic.req_poller.id
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

# デッドレター用関数

locals {
  func_poller = "${var.prefix}-poller"
}

data "archive_file" "func_poller" {
  type        = "zip"
  source_dir  = "./src"
  output_path = "/tmp/${local.func_poller}-source.zip"
}

resource "google_storage_bucket_object" "func_poller" {
  name   = "${local.func_poller}-source-${data.archive_file.func_poller.output_md5}.zip"
  bucket = google_storage_bucket.gcf_source.name
  source = data.archive_file.func_poller.output_path
}

resource "google_cloudfunctions2_function" "poller" {
  name     = local.func_poller
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "main"
    environment_variables = {
      GOOGLE_FUNCTION_SOURCE = "poller.py"
    }
    source {
      storage_source {
        bucket = google_storage_bucket.gcf_source.name
        object = google_storage_bucket_object.func_poller.name
      }
    }
  }

  service_config {
    min_instance_count    = 0
    max_instance_count    = 1
    available_cpu         = "1"
    available_memory      = "4Gi"
    timeout_seconds       = 60
    service_account_email = var.functions_sa_email
    environment_variables = {
      PROJECT_ID              = var.project_id
      QUEUE_SUBSCRIPTION_NAME = google_pubsub_subscription.queue.name
    }
  }

  # event_trigger で指定したトピックのサブスクリプションは自動で作成される。
  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.req_poller.id
    service_account_email = var.trigger_sa_email
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
  }

  depends_on = [
    google_storage_bucket_object.func_poller,
    google_storage_bucket.gcf_source
  ]
}
