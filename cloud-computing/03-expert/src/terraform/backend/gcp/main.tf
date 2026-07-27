# Bootstrap GCS remote state bucket
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  type = string
}

variable "location" {
  type    = string
  default = "asia-southeast1"
}

variable "bucket_name" {
  type = string
}

provider "google" {
  project = var.project_id
}

resource "google_storage_bucket" "state" {
  name                        = var.bucket_name
  location                    = var.location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  force_destroy = false
}

output "backend_hcl" {
  value = <<-EOT
    terraform {
      backend "gcs" {
        bucket = "${google_storage_bucket.state.name}"
        prefix = "ccp/prod"
      }
    }
  EOT
}
