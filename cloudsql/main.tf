terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

    # VPCピアリングを削除する際のエラーの回避策として google-beta の version 4.0 を使う
    # https://github.com/hashicorp/terraform-provider-google/issues/16275#issuecomment-1825752152
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

locals {
  enable_deletion_protection = true
}

resource "google_compute_network" "default" {
  name                    = var.prefix
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name                     = var.prefix
  ip_cidr_range            = "10.1.0.0/24"
  network                  = google_compute_network.default.id
  private_ip_google_access = true
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.prefix}-private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.default.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.default.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  provider                = google-beta
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

resource "google_compute_firewall" "allow_sql_iap" {
  name    = "${var.prefix}-allow-sql-iap"
  network = google_compute_network.default.id

  allow {
    protocol = "tcp"
    ports    = [var.sql_proxy_port]
  }

  # IAP経由の接続を許可する
  # 参考ドキュメント: https://cloud.google.com/iap/docs/using-tcp-forwarding#create-firewall-rule
  source_ranges = ["35.235.240.0/20"]

  target_tags = [var.prefix]
}

resource "google_sql_database_instance" "default" {
  name                = var.prefix
  database_version    = "MYSQL_8_0"
  region              = var.region
  deletion_protection = local.enable_deletion_protection
  depends_on          = [google_service_networking_connection.private_vpc_connection]

  settings {
    deletion_protection_enabled = local.enable_deletion_protection
    tier                        = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.default.id
      enable_private_path_for_google_cloud_services = true
    }
  }
}

resource "google_sql_database" "database" {
  name     = var.db_database
  instance = google_sql_database_instance.default.name
}

data "google_secret_manager_secret_version" "db_password" {
  secret  = var.db_pw_secret_id
  version = "latest"
}

resource "google_sql_user" "default" {
  name     = var.db_username
  instance = google_sql_database_instance.default.name
  password = data.google_secret_manager_secret_version.db_password.secret_data
  host     = "%"
}

resource "google_compute_instance" "cloud_sql_proxy" {
  name                      = "${var.prefix}-cloud-sql-proxy"
  machine_type              = "e2-micro"
  zone                      = "${var.region}-a"
  allow_stopping_for_update = true
  deletion_protection       = local.enable_deletion_protection

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.default.id
    subnetwork = google_compute_subnetwork.default.id
  }

  service_account {
    email  = var.service_account
    scopes = ["cloud-platform"]
  }

  metadata = {
    startup-script = templatefile("./startup-script.tpl", {
      ssh_port            = var.ssh_port
      sql_proxy_version   = var.sql_proxy_version
      sql_proxy_port      = var.sql_proxy_port
      sql_connection_name = google_sql_database_instance.default.connection_name
    })
  }

  tags = [var.prefix]
}
