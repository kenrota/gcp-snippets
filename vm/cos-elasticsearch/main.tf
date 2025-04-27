provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "vm" {
  account_id = "${var.prefix}-vm"
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

resource "google_compute_firewall" "allow_tcp_via_iap" {
  name    = "${var.prefix}-allow-tcp-via-iap"
  network = google_compute_network.default.id

  allow {
    protocol = "tcp"
    ports    = [var.ssh_port, "9200"]
  }

  # IAP経由の接続を許可する
  # 参考ドキュメント: https://cloud.google.com/iap/docs/using-tcp-forwarding#create-firewall-rule
  source_ranges = ["35.235.240.0/20"]

  target_tags = [var.prefix]
}

resource "google_compute_instance" "default" {
  name                      = "${var.prefix}-elasticsearch"
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

    access_config {
      // Ephemeral IP
      // コンテナイメージのダウンロードのため。
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    docker run \
      --name elasticsearch \
      --ulimit memlock=-1:-1 \
      --ulimit nofile=65536:65536 \
      --restart=always \
      -e "cluster.name=test-cluster" \
      -e "discovery.type=single-node" \
      -e "xpack.security.enabled=false" \
      -e "ES_JAVA_OPTS=-Xms1g -Xmx1g" \
      -p 9200:9200 \
      -p 9300:9300 \
      docker.elastic.co/elasticsearch/elasticsearch:8.14.3
  EOT

  metadata = {
    google-logging-enabled = "true"
  }

  service_account {
    email  = google_service_account.vm.email
    scopes = ["cloud-platform"]
  }

  tags = [var.prefix]
}

resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.vm.email}"
}
