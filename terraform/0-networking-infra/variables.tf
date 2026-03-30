variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used for resource naming and tags"
  type        = string
  default     = "matt-lyle-terraform-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs. Two are required by RDS subnet group rules."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}
