resource "google_service_account" "run" {
  account_id   = "${var.project_name}-run"
  display_name = "Cloud Run runtime SA"
}

resource "google_secret_manager_secret_iam_member" "run_accessor" {
  secret_id = google_secret_manager_secret.db.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.run.email}"
}

resource "google_project_iam_member" "run_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.run.email}"
}

resource "google_cloud_run_v2_service" "api" {
  name     = "${var.project_name}-api"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.run.email

    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }

    containers {
      image = var.container_image

      ports {
        container_port = 8080
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }
      env {
        name  = "SERVICE_NAME"
        value = "${var.project_name}-api"
      }

      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db.secret_id
            version = "latest"
          }
        }
      }

      # สำหรับ hello image ของ Cloud Run จะข้าม secret ได้ — แอปจริงควร parse JSON
    }

    vpc_access {
      network_interfaces {
        network    = google_compute_network.main.name
        subnetwork = google_compute_subnetwork.private.name
      }
      egress = "PRIVATE_RANGES_ONLY"
    }
  }

  depends_on = [
    google_secret_manager_secret_iam_member.run_accessor,
    google_sql_database_instance.main,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = google_cloud_run_v2_service.api.project
  location = google_cloud_run_v2_service.api.location
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
