resource "random_password" "db" {
  length  = 24
  special = false
}

resource "google_sql_database_instance" "main" {
  name             = "${var.project_name}-pg"
  database_version = "POSTGRES_16"
  region           = var.region

  settings {
    tier              = "db-f1-micro"
    availability_type = "REGIONAL"
    disk_size         = 20
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
    }
  }

  deletion_protection = false
  depends_on          = [google_service_networking_connection.private_vpc]
}

resource "google_compute_global_address" "private_ip_range" {
  name          = "${var.project_name}-sql-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_sql_database" "app" {
  name     = "appdb"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "app" {
  name     = var.db_username
  instance = google_sql_database_instance.main.name
  password = random_password.db.result
}

resource "google_secret_manager_secret" "db" {
  secret_id = "${var.project_name}-db-credentials"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db" {
  secret = google_secret_manager_secret.db.id
  secret_data = jsonencode({
    username = var.db_username
    password = random_password.db.result
    host     = google_sql_database_instance.main.private_ip_address
    port     = 5432
    dbname   = "appdb"
  })
}
