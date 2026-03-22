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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
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

# Both the helm and kubernetes providers authenticate via the aws_eks_cluster_auth
# data source — no aws CLI binary required, works in Concourse too.
# config_path="" explicitly disables kubeconfig loading so there is no fallback
# to exec-based auth (e.g. ~/.kube/config entries created by aws eks update-kubeconfig).
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.this.token
    config_path            = ""
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.this.token
  config_path            = ""
}
