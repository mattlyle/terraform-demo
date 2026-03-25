terraform {
  required_version = ">= 1.5"

  backend "s3" {
    bucket         = "matt-lyle-terraform-demo-tfstate"
    key            = "matt-lyle-terraform-demo/eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "matt-lyle-terraform-demo-tfstate-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Fetch cluster details and a short-lived token via the AWS API.
# No aws CLI binary required — works in any environment with IAM credentials.
# The cluster name is a static local so these resolve even during plan.
data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}


