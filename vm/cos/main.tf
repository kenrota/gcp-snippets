provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "default" {
  name                    = "${var.prefix}-example"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name                     = "${var.prefix}-example"
  ip_cidr_range            = "10.1.0.0/24"
  network                  = google_compute_network.default.id
  private_ip_google_access = true
}

resource "google_compute_instance" "default" {
  name                      = "${var.prefix}-example"
  machine_type              = "e2-medium"
  zone                      = "${var.region}-a"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    network    = google_compute_network.default.id
    subnetwork = google_compute_subnetwork.default.id
  }

  metadata = {
    gce-container-declaration = <<-EOT
spec:
  containers:
    - name: my-container
      image: ${var.container_image}
      stdin: false
      tty: false
  restartPolicy: Never
EOT
    google-logging-enabled    = "true"
  }

  service_account {
    email  = var.service_account
    scopes = ["cloud-platform"]
  }
}

resource "google_artifact_registry_repository_iam_member" "artifact_reader" {
  project    = var.project_id
  location   = var.region
  repository = var.repository_name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.service_account}"
}

resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${var.service_account}"
}
