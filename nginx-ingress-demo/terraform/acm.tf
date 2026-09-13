# =============================================================================
# acm.tf
# =============================================================================
# Creates an ACM (AWS Certificate Manager) TLS certificate for HTTPS.
#
# WHY ACM?
#   - Free TLS certificates from AWS
#   - Auto-renewal (no manual cert rotation)
#   - Directly integrates with ALB — no cert files to manage
#   - Wildcard cert covers all subdomains (*.example.com)
#
# HOW VALIDATION WORKS (DNS validation):
#   1. ACM gives you a CNAME record to add to Route53
#   2. Terraform automatically adds this CNAME to Route53
#   3. ACM verifies you own the domain by checking the CNAME
#   4. Certificate is issued (takes 1-5 minutes)
#   5. Auto-renews before expiry — no action needed
#
# WHY DNS VALIDATION over EMAIL VALIDATION?
#   - Fully automated — no human action needed
#   - Works for wildcard certs
#   - Better for CI/CD pipelines
#
# FLOW:
#   ACM issues cert → ALB uses cert → HTTPS traffic terminates at ALB
#   → HTTP traffic forwarded to Nginx inside cluster
# =============================================================================

# -----------------------------------------------------------------------------
# Fetch the Route53 hosted zone for your domain
# -----------------------------------------------------------------------------
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# -----------------------------------------------------------------------------
# ACM Certificate
# -----------------------------------------------------------------------------
# Wildcard cert covers: app.example.com, api.example.com, *.example.com
# -----------------------------------------------------------------------------
resource "aws_acm_certificate" "main" {
  domain_name = var.domain_name

  # Wildcard covers all subdomains — one cert for everything
  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  # DNS validation is automated via Route53 below
  validation_method = "DNS"

  # Required when updating cert — creates new cert before destroying old one
  # Prevents downtime during cert updates
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-acm-cert"
  }
}

# -----------------------------------------------------------------------------
# DNS Validation Records
# -----------------------------------------------------------------------------
# ACM provides CNAME records that prove you own the domain.
# Terraform automatically creates these in Route53.
# ACM checks these records and issues the certificate.
# -----------------------------------------------------------------------------
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# -----------------------------------------------------------------------------
# Wait for Certificate Validation
# -----------------------------------------------------------------------------
# Terraform waits here until ACM confirms the cert is issued.
# This ensures downstream resources (ALB) don't try to use an unvalidated cert.
# -----------------------------------------------------------------------------
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}
