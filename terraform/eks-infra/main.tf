# Pull VPC outputs written by the networking-infra root module
data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "matt-lyle-terraform-demo-tfstate"
    key    = "matt-lyle-terraform-demo/networking/terraform.tfstate"
    region = var.aws_region
  }
}

module "eks" {
  source = "../modules/eks"

  cluster_name             = local.cluster_name
  vpc_id                   = local.vpc_id
  private_subnet_ids       = local.private_subnet_ids
  api_server_allowed_cidrs = var.api_server_allowed_cidrs
  node_instance_type       = var.node_instance_type
  node_desired_size        = var.node_desired_size
  node_min_size            = var.node_min_size
  node_max_size            = var.node_max_size
  tags                     = local.common_tags
}

# Used to construct the ECR registry URL output
data "aws_caller_identity" "current" {}
