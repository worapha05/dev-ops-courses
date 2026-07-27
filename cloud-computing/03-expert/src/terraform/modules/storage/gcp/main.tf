variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}

resource "google_storage_bucket" "this" {
  name                        = var.name
  location                    = var.location
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = var.labels

  versioning {
    enabled = true
  }
}

output "bucket_name" {
  value = google_storage_bucket.this.name
}

output "bucket_url" {
  value = google_storage_bucket.this.url
}
