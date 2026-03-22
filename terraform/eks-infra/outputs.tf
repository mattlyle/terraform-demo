output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate"
  value       = module.eks.cluster_ca_certificate
  sensitive   = true
}

output "node_security_group_id" {
  description = "Security group ID on EKS nodes — referenced by RDS security group rules"
  value       = module.eks.node_security_group_id
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN — used by sqs-infra to create IRSA trust policies"
  value       = module.eks.oidc_provider_arn
}

output "ecr_registry" {
  description = "ECR registry host — e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}
