variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "asia-southeast1"
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "asia-southeast1-a"
}

variable "project_name" {
  type        = string
  description = "Name prefix for resources"
  default     = "ccp-bootcamp"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"
}

variable "bucket_suffix" {
  type        = string
  description = "Unique suffix to avoid global GCS name collisions"
}

variable "machine_type" {
  type        = string
  description = "GCE machine type"
  default     = "e2-micro"
}
