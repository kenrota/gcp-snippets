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

resource "google_compute_firewall" "allow_http_iap" {
  name    = "${var.prefix}-allow-http-iap"
  network = google_compute_network.default.id

  allow {
    protocol = "tcp"
    ports    = [8080]
  }

  # IAP経由の接続を許可する
  # 参考ドキュメント: https://cloud.google.com/iap/docs/using-tcp-forwarding#create-firewall-rule
  source_ranges = ["35.235.240.0/20"]

  target_tags = [var.prefix]
}

resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "${var.prefix}-allow-ssh-iap"
  network = google_compute_network.default.id

  allow {
    protocol = "tcp"
    ports    = [var.ssh_port]
  }

  # IAP経由の接続を許可する
  # 参考ドキュメント: https://cloud.google.com/iap/docs/using-tcp-forwarding#create-firewall-rule
  source_ranges = ["35.235.240.0/20"]

  target_tags = [var.prefix]
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

  tags = [var.prefix]
}
