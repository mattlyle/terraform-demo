# ── EKS ───────────────────────────────────────────────────────────────────────
# Uncomment when module "eks" is defined in main.tf

# output "cluster_name" {
#   description = "EKS cluster name"
#   value       = module.eks.cluster_name
# }

# output "cluster_endpoint" {
#   description = "EKS API server endpoint"
#   value       = module.eks.cluster_endpoint
# }

# output "cluster_ca_certificate" {
#   description = "Base64-encoded cluster CA certificate"
#   value       = module.eks.cluster_ca_certificate
#   sensitive   = true
# }

# output "node_security_group_id" {
#   description = "Security group ID attached to EKS nodes"
#   value       = module.eks.node_security_group_id
# }
