terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_storage_bucket" "assets" {
  name                        = "${var.project_name}-assets-${var.bucket_suffix}"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      days_since_noncurrent_time = 90
      with_state                 = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    env     = var.environment
    project = var.project_name
  }
}

resource "google_service_account" "vm" {
  account_id   = "${var.project_name}-vm"
  display_name = "CCP Bootcamp VM SA"
}

resource "google_storage_bucket_iam_member" "vm_reader" {
  bucket = google_storage_bucket.assets.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.vm.email}"
}

resource "google_compute_firewall" "http" {
  name    = "${var.project_name}-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_instance_template" "web" {
  name_prefix  = "${var.project_name}-tpl-"
  machine_type = var.machine_type
  tags         = ["http-server"]

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
    access_config {}
  }

  service_account {
    email  = google_service_account.vm.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    echo ok > /var/www/html/healthz
    systemctl enable --now nginx
  EOT

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "web" {
  name               = "${var.project_name}-mig"
  base_instance_name = "${var.project_name}-web"
  zone               = var.zone
  target_size        = 2

  version {
    instance_template = google_compute_instance_template.web.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.http.id
    initial_delay_sec = 60
  }
}

resource "google_compute_health_check" "http" {
  name = "${var.project_name}-http-hc"

  http_health_check {
    port         = 80
    request_path = "/healthz"
  }
}

resource "google_compute_autoscaler" "web" {
  name   = "${var.project_name}-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.web.id

  autoscaling_policy {
    max_replicas    = 3
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.6
    }
  }
}

resource "google_project_iam_custom_role" "storage_reader" {
  role_id     = replace("${var.project_name}_storage_reader", "-", "_")
  title       = "CCP Storage Reader"
  description = "Minimal object read permissions"
  permissions = [
    "storage.objects.get",
    "storage.objects.list",
    "storage.buckets.get",
  ]
}
