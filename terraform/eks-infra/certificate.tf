# ── TLS / ACM Certificate ────────────────────────────────────────────────────
# Not provisioned here — an ACM certificate will be wired in when app Ingresses
# are deployed. The tls_self_signed_cert approach was removed because ACM rejects
# certs whose not_before timestamp is in the future, which happens when WSL2's
# clock has any forward drift.
#
# When ready, choose one of:
#
# Option A — ACM-managed cert with DNS validation (recommended):
#   resource "aws_acm_certificate" "this" {
#     domain_name       = "your-domain.com"
#     validation_method = "DNS"
#   }
#   Then reference aws_acm_certificate_validation.this.certificate_arn in outputs.
#
# Option B — Import an externally-generated cert (avoid clock drift):
#   Generate the cert on any machine with a stable clock:
#     openssl req -x509 -newkey rsa:2048 -sha256 \
#       -keyout key.pem -out cert.pem -days 3650 -nodes \
#       -subj '/CN=matt-lyle-terraform-demo.local'
#   Then import:
#     aws acm import-certificate \
#       --certificate file://cert.pem --private-key file://key.pem
#   Hardcode the returned ARN directly in the app Ingress annotations.
# ─────────────────────────────────────────────────────────────────────────────
