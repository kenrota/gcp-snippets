provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "run" {
  account_id = "${var.prefix}-run"
}

resource "google_cloud_run_v2_service" "default" {
  name                = "${var.prefix}-hello-app"
  location            = var.region
  project             = var.project_id
  deletion_protection = false

  template {
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      ports {
        name           = "http1"
        container_port = 8080
      }
    }
    service_account = google_service_account.run.email
  }
}

resource "google_cloud_run_service_iam_member" "member" {
  location = google_cloud_run_v2_service.default.location
  project  = google_cloud_run_v2_service.default.project
  service  = google_cloud_run_v2_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_compute_global_address" "default" {
  name = "${var.prefix}-address"
}

resource "google_compute_region_network_endpoint_group" "default" {
  name                  = "${var.prefix}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_v2_service.default.name
  }
}

resource "google_compute_backend_service" "default" {
  name        = "${var.prefix}-backend"
  protocol    = "HTTP"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.default.id
  }
}

resource "google_compute_url_map" "default" {
  name            = "${var.prefix}-urlmap"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_target_http_proxy" "default" {
  name    = "${var.prefix}-http-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "${var.prefix}-lb"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}

output "load_balancer_http_endpoint" {
  value = "http://${google_compute_global_address.default.address}"
}
