locals {
  cluster_name = "${var.project_name}-eks"

  # Outputs from networking-infra remote state
  vpc_id             = data.terraform_remote_state.networking.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.networking.outputs.public_subnet_ids

  # Outputs from eks-infra remote state
  node_security_group_id = data.terraform_remote_state.eks.outputs.node_security_group_id

  common_tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
    Component = "rds"
  }
}
