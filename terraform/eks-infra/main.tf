# Pull VPC outputs written by the networking-infra root module
data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "matt-lyle-terraform-demo-tfstate"
    key    = "matt-lyle-terraform-demo/networking/terraform.tfstate"
    region = var.aws_region
  }
}

# ── EKS cluster ───────────────────────────────────────────────────────────────
# module "eks" {
#   source = "../modules/eks"
#
#   project_name       = var.project_name
#   cluster_name       = local.cluster_name
#   vpc_id             = local.vpc_id
#   private_subnet_ids = local.private_subnet_ids
#   tags               = local.common_tags
# }
