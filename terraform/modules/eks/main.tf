module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Public endpoint restricted to a specific IP — run kubectl from your laptop
  # without opening the API server to the whole internet.
  # Update cluster_endpoint_public_access_cidrs when your IP changes.
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.api_server_allowed_cidrs

  # Enable all control plane log types → CloudWatch.
  # Good demo talking point: audit logs show every API server call.
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  # Grant the Terraform caller (the IAM user/role running apply) admin access
  # to the cluster via EKS access entries — no manual aws-auth ConfigMap editing.
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # IMDSv2 required — prevents pods from using the metadata endpoint to
      # steal node IAM credentials via SSRF.
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }
    }
  }

  tags = var.tags
}
