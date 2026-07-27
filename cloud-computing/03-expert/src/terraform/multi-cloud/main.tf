# Multi-cloud / multi-region orchestration ตัวอย่าง:
# - AWS primary + secondary ALB หลัง Route 53 failover (Active-Passive)
# - GCS + S3 เป็น object stores คู่กัน (logical multi-cloud)
#
# หมายเหตุ: ต้องมี ALB DNS จากแต่ละ region (ใช้ terraform_remote_state หรือใส่ตัวแปร)

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_name" {
  default = "ccp-xprt"
}

variable "hosted_zone_id" {
  type        = string
  description = "Route 53 hosted zone ID"
}

variable "dns_name" {
  type        = string
  description = "เช่น app.example.com"
}

variable "primary_alb_dns" {
  type = string
}

variable "primary_alb_zone_id" {
  type = string
}

variable "secondary_alb_dns" {
  type = string
}

variable "secondary_alb_zone_id" {
  type = string
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_dr_bucket" {
  type = string
}

provider "aws" {
  region = "ap-southeast-1"
  alias  = "primary"
}

provider "google" {
  project = var.gcp_project_id
}

resource "aws_route53_health_check" "primary" {
  fqdn              = var.primary_alb_dns
  port              = 80
  type              = "HTTP"
  resource_path     = "/healthz"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "${var.project_name}-primary-hc"
  }
}

resource "aws_route53_record" "primary" {
  zone_id        = var.hosted_zone_id
  name           = var.dns_name
  type           = "A"
  set_identifier = "primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id

  alias {
    name                   = var.primary_alb_dns
    zone_id                = var.primary_alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "secondary" {
  zone_id        = var.hosted_zone_id
  name           = var.dns_name
  type           = "A"
  set_identifier = "secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = var.secondary_alb_dns
    zone_id                = var.secondary_alb_zone_id
    evaluate_target_health = true
  }
}

# Object store ฝั่ง GCP สำหรับสำเนา DR / multi-cloud artifact
module "gcp_dr_bucket" {
  source   = "../modules/storage/gcp"
  name     = var.gcp_dr_bucket
  location = "ASIA"

  labels = {
    purpose = "dr"
    project = var.project_name
  }
}

output "failover_record" {
  value = aws_route53_record.primary.fqdn
}

output "gcp_dr_bucket" {
  value = module.gcp_dr_bucket.bucket_name
}
