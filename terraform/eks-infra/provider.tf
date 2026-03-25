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

# Kubernetes provider — configured after EKS cluster is up.
# Uses aws_eks_cluster_auth data source rather than an exec block so it works
# inside the Concourse Terraform task image (which has no aws CLI binary).
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
