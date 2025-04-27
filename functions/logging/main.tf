provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "function" {
  account_id = "${var.prefix}-function"
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

locals {
  function_name = "${var.prefix}-http"
}

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

resource "google_cloudfunctions2_function" "http" {
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
  }
}

resource "google_cloud_run_service_iam_member" "member" {
  location = google_cloudfunctions2_function.http.location
  service  = google_cloudfunctions2_function.http.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "function_name" {
  value = google_cloudfunctions2_function.http.name
}

output "http_public_endpoint_uri" {
  value = google_cloudfunctions2_function.http.url
}
