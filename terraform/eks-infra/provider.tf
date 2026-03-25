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
# Used to manage cluster-level resources (e.g. StorageClass) alongside the
# AWS resources that depend on them, without a separate kubectl step.
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
  }
}
