# Pull outputs written by the networking-infra root module
data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "matt-lyle-terraform-demo-tfstate"
    key    = "matt-lyle-terraform-demo/networking/terraform.tfstate"
    region = var.aws_region
  }
}

# Pull outputs written by the eks-infra root module (node_security_group_id)
data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "matt-lyle-terraform-demo-tfstate"
    key    = "matt-lyle-terraform-demo/eks/terraform.tfstate"
    region = var.aws_region
  }
}

module "rds" {
  source = "../modules/rds"

  project_name           = var.project_name
  cluster_name           = local.cluster_name
  vpc_id                 = local.vpc_id
  private_subnet_ids     = local.private_subnet_ids
  public_subnet_ids      = local.public_subnet_ids
  node_security_group_id = local.node_security_group_id
  allowed_admin_cidrs    = var.allowed_admin_cidrs
  db_instance_class      = var.db_instance_class
  db_name                = var.db_name
  db_username            = var.db_username
  tags                   = local.common_tags
}

# ── RDS ───────────────────────────────────────────────────────────────────────
# module "rds" {
#   source = "../modules/rds"
#
#   project_name       = var.project_name
#   vpc_id             = local.vpc_id
#   private_subnet_ids = local.private_subnet_ids
#   vpc_cidr_block     = local.vpc_cidr_block
#   tags               = local.common_tags
# }
