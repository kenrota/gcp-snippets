terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.12.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
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
  function_name = "${var.prefix}-honojs-example"
}

data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "./src"
  output_path = "/tmp/${local.function_name}-source.zip"
  excludes = [
    "node_modules",
  ]
}

resource "google_storage_bucket_object" "function_archive" {
  name   = "${local.function_name}-source-${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.gcf_source.name
  source = data.archive_file.function_source.output_path
}

resource "google_cloudfunctions2_function" "default" {
  name     = local.function_name
  location = var.region

  build_config {
    runtime     = "nodejs20"
    entry_point = "httpFunction"
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
    service_account_email = var.service_account
  }
}

# Allow all users to invoke the function
resource "google_cloud_run_service_iam_member" "function_invoker" {
  location = google_cloudfunctions2_function.default.location
  service  = google_cloudfunctions2_function.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "function_url" {
  value = google_cloudfunctions2_function.default.url
}
