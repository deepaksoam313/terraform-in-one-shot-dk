# =============================================================================
# route53.tf
# =============================================================================
# Creates DNS records pointing your domain to the ALB.
#
# HOW DNS WORKS IN THIS SETUP:
#
#   User types: https://app.example.com
#       │
#       ▼
#   Route53 looks up app.example.com
#       │
#       ▼
#   Returns ALB DNS name (via ALIAS record)
#       │
#       ▼
#   User connects to ALB → HTTPS terminates → traffic enters cluster
#
# WHY ALIAS RECORD instead of CNAME?
#   - ALIAS is AWS-specific, works at zone apex (example.com itself)
#   - CNAME cannot be used at zone apex
#   - ALIAS is free (no charge per query like CNAME)
#   - ALIAS automatically follows ALB DNS changes
#
# HOW DO WE GET THE ALB DNS NAME?
#   AWS LBC creates the ALB when we apply the ALB Ingress (alb-ingress.yaml).
#   The ALB DNS name is then available as a K8s Ingress status.
#   We use a data source to fetch it after ALB is created.
#
# NOTE: The ALB is created by Helm/K8s (alb-ingress.yaml), not Terraform.
#       So the Route53 record below references the ALB DNS via a data source
#       that reads the K8s Ingress status after ALB is provisioned.
# =============================================================================

# -----------------------------------------------------------------------------
# Fetch ALB DNS name from K8s Ingress status
# -----------------------------------------------------------------------------
# After AWS LBC creates the ALB, its DNS name is stored in the
# Ingress resource status. We read it here to create the Route53 record.
# -----------------------------------------------------------------------------
data "kubernetes_ingress_v1" "alb" {
  metadata {
    name      = "alb-to-nginx"
    namespace = "ingress-nginx"
  }

  # Wait until ALB is provisioned and has a hostname
  depends_on = [helm_release.nginx_ingress, helm_release.aws_lbc]
}

# -----------------------------------------------------------------------------
# Route53 A Record (ALIAS) → ALB
# -----------------------------------------------------------------------------
# Points app.example.com → ALB DNS name
# ALIAS record is free and auto-updates if ALB DNS changes
# -----------------------------------------------------------------------------
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.app_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = data.kubernetes_ingress_v1.alb.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_elb_hosted_zone_id.main.id
    evaluate_target_health = true   # Route53 health checks ALB before routing
  }
}

# -----------------------------------------------------------------------------
# ALB Hosted Zone ID
# -----------------------------------------------------------------------------
# Each AWS region has a fixed hosted zone ID for ALBs.
# Required for ALIAS records pointing to ALBs.
# -----------------------------------------------------------------------------
data "aws_elb_hosted_zone_id" "main" {}
