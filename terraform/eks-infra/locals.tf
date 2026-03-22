locals {
  cluster_name = "${var.project_name}-eks"

  # Networking outputs pulled from the networking-infra remote state
  vpc_id             = data.terraform_remote_state.networking.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids
  vpc_cidr_block     = data.terraform_remote_state.networking.outputs.vpc_cidr_block

  common_tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
    Component = "eks"
  }
}
