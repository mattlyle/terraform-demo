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

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name to create"
  type        = string
  default     = "demo"
}

variable "db_username" {
  description = "Master database username"
  type        = string
  default     = "demouser"
}
