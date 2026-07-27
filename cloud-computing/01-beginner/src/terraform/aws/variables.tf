variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile name"
  default     = "bootcamp"
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
  description = "Unique suffix to avoid global S3 name collisions"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}
