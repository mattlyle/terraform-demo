module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Public endpoint restricted to a specific IP — run kubectl from your laptop
  # without opening the API server to the whole internet.
  # Update cluster_endpoint_public_access_cidrs when your IP changes.
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.api_server_allowed_cidrs

  # Enable all control plane log types → CloudWatch.
  # Good demo talking point: audit logs show every API server call.
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  # Grant the Terraform caller (the IAM user/role running apply) admin access
  # to the cluster via EKS access entries — no manual aws-auth ConfigMap editing.
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    demo-eks-nodes = {
      instance_types = [var.node_instance_type]

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # IMDSv2 required — prevents pods from using the metadata endpoint to
      # steal node IAM credentials via SSRF.
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }

      iam_role_additional_policies = {
        sqs = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
      }
    }
  }

  tags = var.tags
}
# The default node-to-node rule only covers ephemeral ports (1025-65535).
# Port 80 is needed for nginx ingress → frontend pod traffic across nodes.
resource "aws_security_group_rule" "node_to_node_http" {
  description              = "Node to node HTTP (port 80) — ingress controller to frontend pods"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.eks.node_security_group_id
}
# The EBS CSI driver is required for PersistentVolumeClaims backed by EBS.
# Without it, StatefulSets (e.g. Concourse PostgreSQL) stay Pending.
# Uses IRSA so the controller pod has its own IAM identity — avoids the
# IMDSv2 hop-limit issue (hop_limit=1 blocks pod-level IMDS access).
resource "aws_iam_role" "ebs_csi_driver" {
  name = "${module.eks.cluster_name}-ebs-csi-driver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = module.eks.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi_driver.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = var.tags

  depends_on = [aws_iam_role_policy_attachment.ebs_csi_driver]
}

# vpc-cni manages pod IP allocation from the VPC CIDR.
# resource "aws_eks_addon" "vpc_cni" {
#   cluster_name                = module.eks.cluster_name
#   addon_name                  = "vpc-cni"
#   resolve_conflicts_on_create = "OVERWRITE"
#   resolve_conflicts_on_update = "OVERWRITE"
#   tags                        = var.tags
# }

# coredns provides cluster-internal DNS resolution.
# resource "aws_eks_addon" "coredns" {
#   cluster_name                = module.eks.cluster_name
#   addon_name                  = "coredns"
#   resolve_conflicts_on_create = "OVERWRITE"
#   resolve_conflicts_on_update = "OVERWRITE"
#   tags                        = var.tags
# }

# kube-proxy maintains network rules on each node for Service routing.
# resource "aws_eks_addon" "kube_proxy" {
#   cluster_name                = module.eks.cluster_name
#   addon_name                  = "kube-proxy"
#   resolve_conflicts_on_create = "OVERWRITE"
#   resolve_conflicts_on_update = "OVERWRITE"
#   tags                        = var.tags
# }
