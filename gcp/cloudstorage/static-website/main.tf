provider "google" {
  project = var.project_id
  region  = var.region
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "google_storage_bucket" "static_website" {
  name                        = "static-website-${random_id.bucket_suffix.hex}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket_iam_member" "allow_public_read" {
  bucket = google_storage_bucket.static_website.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_storage_bucket_object" "default_html" {
  name         = "index.html"
  bucket       = google_storage_bucket.static_website.name
  source       = "index.html"
  content_type = "text/html"
}

resource "google_storage_bucket_object" "default_css" {
  name         = "styles.css"
  bucket       = google_storage_bucket.static_website.name
  source       = "styles.css"
  content_type = "text/css"
}

resource "google_storage_bucket_object" "default_js" {
  name         = "script.js"
  bucket       = google_storage_bucket.static_website.name
  source       = "script.js"
  content_type = "application/javascript"
}

output "website_url" {
  value = "https://storage.googleapis.com/${google_storage_bucket.static_website.name}/index.html"
}
