variable "project_name" {
  description = "Short name used for SSM parameter paths and resource naming"
  type        = string
}

variable "cluster_name" {
  description = "Name used to prefix RDS resources (typically <project>-eks for consistency)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy the RDS instance into"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "EKS node security group — only this SG is allowed to connect on port 5432"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "demo"
}

variable "db_username" {
  description = "Master database username"
  type        = string
  default     = "demouser"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
