variable "project_name" {
  description = "Short name used for resource naming"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_offset" {
  description = "Third-octet offset for public subnets. e.g. 10 → 10.10.10.0/24, 10.10.11.0/24"
  type        = number
  default     = 10
}

variable "private_subnet_offset" {
  description = "Third-octet offset for private subnets. e.g. 20 → 10.10.20.0/24, 10.10.21.0/24"
  type        = number
  default     = 20
}

variable "availability_zones" {
  description = "List of AZs to deploy subnets into"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "cluster_name" {
  description = "EKS cluster name — used to tag subnets for load-balancer controller discovery"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources in this module"
  type        = map(string)
  default     = {}
}
