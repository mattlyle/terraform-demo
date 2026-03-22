output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (one per AZ)"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (one per AZ) — used by EKS and RDS"
  value       = module.vpc.private_subnets
}

output "vpc_cidr_block" {
  description = "Primary CIDR block of the VPC — useful for security group ingress rules"
  value       = module.vpc.vpc_cidr_block
}
