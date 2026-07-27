output "bucket_name" {
  value = google_storage_bucket.assets.name
}

output "mig_name" {
  value = google_compute_instance_group_manager.web.name
}

output "vm_service_account" {
  value = google_service_account.vm.email
}

output "custom_role_id" {
  value = google_project_iam_custom_role.storage_reader.id
}
