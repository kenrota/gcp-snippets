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

resource "google_storage_bucket" "app_bucket" {
  name                        = "${var.prefix}-app-deploy-${random_id.bucket_suffix.hex}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

data "archive_file" "app_zip" {
  type        = "zip"
  source_dir  = "./app"
  output_path = "/tmp/${var.prefix}-app.zip"
}

resource "google_storage_bucket_object" "app_zip" {
  name   = "${var.prefix}-app.zip"
  bucket = google_storage_bucket.app_bucket.name
  source = data.archive_file.app_zip.output_path
}

resource "google_app_engine_standard_app_version" "my_service" {
  version_id                = "${formatdate("YYYYMMDD", timestamp())}t${formatdate("hhmmss", timestamp())}"
  service                   = "${var.prefix}-my-service"
  runtime                   = "python311"
  delete_service_on_destroy = true

  entrypoint {
    shell = "gunicorn -b :$PORT main:app"
  }

  deployment {
    zip {
      source_url = "https://storage.googleapis.com/${google_storage_bucket.app_bucket.name}/${google_storage_bucket_object.app_zip.name}"
    }
  }

  automatic_scaling {
    standard_scheduler_settings {
      target_cpu_utilization = 0.5
      min_instances          = 0
      max_instances          = 1
    }
  }
}

resource "google_iap_web_iam_member" "allow_iap_access" {
  count   = length(var.allowed_accesser_users)
  project = var.project_id
  role    = "roles/iap.httpsResourceAccessor"
  member  = "user:${var.allowed_accesser_users[count.index]}"
}
