output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (one per AZ)"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (one per AZ) — used by EKS and RDS"
  value       = module.vpc.private_subnet_ids
}

output "vpc_cidr_block" {
  description = "Primary CIDR of the VPC — referenced by eks-infra and rds-infra security groups"
  value       = module.vpc.vpc_cidr_block
}

output "flow_logs_log_group" {
  description = "CloudWatch Logs group name for VPC flow logs — open in Logs Insights to query traffic"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}
