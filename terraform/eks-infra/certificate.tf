# ── TLS Certificate ───────────────────────────────────────────────────────────
# Uses a self-signed certificate imported into ACM so the ALB can terminate HTTPS.
#
# ── TO UPGRADE TO A REAL CERTIFICATE ─────────────────────────────────────────
# Option A — ACM-managed cert with DNS validation (recommended):
#   1. Register/transfer your domain into Route 53 (or any DNS provider).
#   2. Replace this entire file with:
#
#      resource "aws_acm_certificate" "this" {
#        domain_name       = "your-domain.com"
#        validation_method = "DNS"
#        subject_alternative_names = ["*.your-domain.com"]
#      }
#
#      resource "aws_route53_record" "cert_validation" {
#        for_each = {
#          for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => dvo
#        }
#        zone_id = data.aws_route53_zone.this.zone_id
#        name    = each.value.resource_record_name
#        type    = each.value.resource_record_type
#        records = [each.value.resource_record_value]
#        ttl     = 60
#      }
#
#      resource "aws_acm_certificate_validation" "this" {
#        certificate_arn         = aws_acm_certificate.this.arn
#        validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
#      }
#
#   3. Update the output below to reference aws_acm_certificate_validation.this.certificate_arn
#
# Option B — Import an existing cert you already own:
#   aws acm import-certificate \
#     --certificate file://cert.pem \
#     --private-key file://key.pem \
#     --certificate-chain file://chain.pem
#   Then hardcode the returned ARN in the output below and delete everything else.
# ─────────────────────────────────────────────────────────────────────────────

# Self-signed private key
resource "tls_private_key" "self_signed" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Self-signed certificate — valid for 1 year, CN matches the project name
resource "tls_self_signed_cert" "self_signed" {
  private_key_pem = tls_private_key.self_signed.private_key_pem

  subject {
    common_name  = "${var.project_name}.local"
    organization = var.project_name
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Import into ACM so the ALB can reference it — ALB only accepts ACM certificates
resource "aws_acm_certificate" "self_signed" {
  private_key      = tls_private_key.self_signed.private_key_pem
  certificate_body = tls_self_signed_cert.self_signed.cert_pem

  # TO UPGRADE: delete this resource and replace with a DNS-validated ACM cert
  # (see comments at the top of this file)

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN — use in Ingress annotation: alb.ingress.kubernetes.io/certificate-arn"
  value       = aws_acm_certificate.self_signed.arn
}
