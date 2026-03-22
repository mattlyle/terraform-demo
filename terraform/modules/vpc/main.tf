module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs = var.availability_zones

  # Public subnets: 10.10.10.0/24, 10.10.11.0/24, ...
  public_subnets = [
    for i, _ in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, var.public_subnet_offset + i)
  ]

  # Private subnets: 10.10.20.0/24, 10.10.21.0/24, ...
  private_subnets = [
    for i, _ in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, var.private_subnet_offset + i)
  ]

  # Required for EKS control plane → node DNS resolution
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Single NAT gateway — cost-effective for a demo
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # Tags required by the AWS load-balancer controller for subnet discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  tags = var.tags
}
