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
