provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "default" {
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name                     = "${var.prefix}-subnet"
  network                  = google_compute_network.default.id
  ip_cidr_range            = "10.2.0.0/28"
  private_ip_google_access = true
  region                   = var.region
}

resource "google_dns_record_set" "internal_dns" {
  name         = "vm.internal.demo."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.private_zone.name
  rrdatas      = [google_compute_instance.vm.network_interface[0].network_ip]
}

resource "google_compute_firewall" "allow_internal_8080" {
  name    = "${var.prefix}-allow-internal-8080"
  network = google_compute_network.default.id

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = [google_compute_subnetwork.default.ip_cidr_range]
  target_tags   = ["${var.prefix}-allow-internal-8080"]
}

resource "google_dns_managed_zone" "private_zone" {
  name       = "${var.prefix}-internal-zone"
  dns_name   = "internal.demo."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.default.id
    }
  }
}

resource "google_vpc_access_connector" "default" {
  name = "${var.prefix}-vpc-connector"
  subnet {
    name = google_compute_subnetwork.default.name
  }
  machine_type  = "e2-standard-4"
  min_instances = 2
  max_instances = 3
  region        = var.region
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

resource "google_compute_instance" "vm" {
  name                = "${var.prefix}-vm"
  machine_type        = "e2-micro"
  zone                = "${var.region}-a"
  deletion_protection = false

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.default.id
    subnetwork = google_compute_subnetwork.default.id
  }

  tags = ["allow-internal-8080"]

  metadata_startup_script = <<-EOF
    #!/bin/bash
    mkdir -p /var/www/html
    echo "Hello, from VM" > /var/www/html/index.html
    cd /var/www/html
    nohup python3 -m http.server 8080 &
  EOF
}

resource "google_storage_bucket" "gcf_source" {
  name                        = "${var.prefix}-gcf-source-${random_id.bucket_suffix.hex}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_pubsub_topic" "trigger" {
  name = "${var.prefix}-trigger"
}

resource "google_cloud_scheduler_job" "trigger" {
  name      = "${var.prefix}-trigger"
  schedule  = "*/1 * * * *"
  time_zone = "Asia/Tokyo"

  pubsub_target {
    topic_name = google_pubsub_topic.trigger.id
    data       = base64encode("test")
  }

  retry_config {
    retry_count = 0
  }
}

data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "./src"
  output_path = "/tmp/function-source.zip"
}

resource "google_storage_bucket_object" "function_archive" {
  name   = "function-source-${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.gcf_source.name
  source = data.archive_file.function_source.output_path
}

resource "google_cloudfunctions2_function" "monitor" {
  name     = "${var.prefix}-monitor"
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
    service_account_email = var.functions_sa_email
    environment_variables = {
      LOG_EXECUTION_ID = "true"
      VM_DNS_NAME      = "vm.internal.demo"
    }
    ingress_settings              = "ALLOW_INTERNAL_ONLY"
    vpc_connector                 = google_vpc_access_connector.default.name
    vpc_connector_egress_settings = "ALL_TRAFFIC"
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.trigger.id
    service_account_email = var.trigger_sa_email
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
  }
}

resource "google_cloud_run_service_iam_member" "function_invoker" {
  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.monitor.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.trigger_sa_email}"
}
