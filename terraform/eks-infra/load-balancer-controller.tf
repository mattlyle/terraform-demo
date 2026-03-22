# ── AWS Load Balancer Controller ──────────────────────────────────────────────
# Enables ALB creation from Kubernetes Ingress resources.
# HTTP → HTTPS redirect is configured per-Ingress via annotations:
#
#   alb.ingress.kubernetes.io/scheme: internet-facing
#   alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80},{"HTTPS":443}]'
#   alb.ingress.kubernetes.io/ssl-redirect: '443'
#
# The certificate ARN comes from the acm_certificate_arn output of this module:
#   alb.ingress.kubernetes.io/certificate-arn: <acm_certificate_arn output>
#
# TO UPGRADE TO A REAL CERT: replace certificate.tf with a DNS-validated ACM
# cert (see comments in certificate.tf) — no changes needed in this file.

# IRSA role — gives the controller pod permission to create/manage ALBs
module "lb_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${local.cluster_name}-aws-lb-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.common_tags
}

# Install the controller via the official eks-charts Helm repository
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.11.0"

  set {
    name  = "clusterName"
    value = local.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  # Annotate the service account with the IRSA role ARN so pods can assume it
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.lb_controller_irsa_role.iam_role_arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = local.vpc_id
  }

  depends_on = [module.eks]
}
