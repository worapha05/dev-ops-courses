variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type    = string
  default = "asia-southeast1"
}

variable "project_name" {
  type    = string
  default = "ccp-mid"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "container_image" {
  type        = string
  description = "Container image for Cloud Run"
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}
