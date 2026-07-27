output "cloud_run_uri" {
  value = google_cloud_run_v2_service.api.uri
}

output "vpc_name" {
  value = google_compute_network.main.name
}

output "sql_private_ip" {
  value = google_sql_database_instance.main.private_ip_address
}

output "secret_id" {
  value = google_secret_manager_secret.db.secret_id
}
