variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "aws_profile" {
  type    = string
  default = "bootcamp"
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
  default = "10.20.0.0/16"
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "container_image" {
  type        = string
  description = "Container image for ECS"
  default     = "public.ecr.aws/docker/library/nginx:alpine"
}

variable "enable_nat_gateway" {
  type        = bool
  description = "NAT มีค่าใช้จ่าย — เปิดเมื่อ task ต้องออก internet (pull image public)"
  default     = true
}
