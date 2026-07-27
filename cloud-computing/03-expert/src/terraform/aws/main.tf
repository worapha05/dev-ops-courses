# ตัวอย่างประกอบ modules ใน region หลัก (Active)
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # เปิดหลังสร้าง backend:
  # backend "s3" { ... }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

variable "aws_region" {
  default = "ap-southeast-1"
}

variable "aws_profile" {
  default = "bootcamp"
}

variable "project_name" {
  default = "ccp-xprt"
}

variable "bucket_suffix" {
  type = string
}

variable "vpc_cidr" {
  default = "10.40.0.0/16"
}

module "network" {
  source   = "../modules/network/aws"
  name     = var.project_name
  cidr     = var.vpc_cidr
  az_count = 2

  tags = {
    Environment = "prod"
    Project     = var.project_name
  }
}

module "storage" {
  source        = "../modules/storage/aws"
  name          = "${var.project_name}-data"
  bucket_suffix = var.bucket_suffix

  tags = {
    Environment = "prod"
    Project     = var.project_name
  }
}

module "compute" {
  source             = "../modules/compute/aws"
  name               = var.project_name
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.public_subnet_ids
  desired_capacity   = 2

  tags = {
    Environment = "prod"
    Project     = var.project_name
  }
}

output "alb_dns" {
  value = module.compute.alb_dns_name
}

output "bucket" {
  value = module.storage.bucket_id
}
