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
}

variable "project_id" {
  type = string
}

variable "region" {
  default = "asia-southeast1"
}

variable "project_name" {
  default = "ccp-xprt"
}

variable "vpc_cidr" {
  default = "10.50.0.0/16"
}

variable "bucket_name" {
  type = string
}

module "network" {
  source     = "../modules/network/gcp"
  name       = var.project_name
  project_id = var.project_id
  region     = var.region
  cidr       = var.vpc_cidr

  labels = {
    env     = "prod"
    project = var.project_name
  }
}

module "storage" {
  source   = "../modules/storage/gcp"
  name     = var.bucket_name
  location = var.region

  labels = {
    env     = "prod"
    project = var.project_name
  }
}

output "network" {
  value = module.network.network_name
}

output "bucket" {
  value = module.storage.bucket_name
}
