# =============================================================================
# waf.tf
# =============================================================================
# Creates AWS WAF v2 and attaches it to the ALB.
#
# WHAT IS WAF?
#   Web Application Firewall — inspects HTTP requests BEFORE they reach
#   your application. Blocks malicious traffic at the AWS edge.
#
# WHY WAF ON ALB?
#   - Blocks bad traffic BEFORE it enters your cluster (saves compute cost)
#   - OWASP Top 10 protection out of the box (SQL injection, XSS etc.)
#   - Rate limiting per IP (DDoS protection)
#   - Geo-blocking (block specific countries)
#   - Custom rules for your app
#
# MANAGED RULE GROUPS (AWS maintains these, auto-updated):
#   - AWSManagedRulesCommonRuleSet     → OWASP Top 10 common threats
#   - AWSManagedRulesKnownBadInputsRuleSet → Known bad inputs (Log4j etc.)
#   - AWSManagedRulesAmazonIpReputationList → Known malicious IPs
#
# WAF FLOW:
#   Request → WAF evaluates rules top to bottom
#           → If rule matches → BLOCK (return 403)
#           → If no rule matches → ALLOW → ALB → Nginx → App
#
# COST NOTE:
#   WAF charges per WebACL ($5/month) + per rule ($1/month) + per request.
#   For prod, this is worth it. For dev/test, you can skip WAF.
# =============================================================================

resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project_name}-waf"
  description = "WAF for ${var.project_name} ALB"
  scope       = "REGIONAL"   # REGIONAL for ALB, CLOUDFRONT for CloudFront

  # Default action: allow all requests that don't match any rule
  default_action {
    allow {}
  }

  # ---------------------------------------------------------------------------
  # Rule 1: AWS Managed Common Rule Set (OWASP Top 10)
  # ---------------------------------------------------------------------------
  # Covers: SQL injection, XSS, path traversal, local file inclusion etc.
  # Priority 1 = evaluated first
  # ---------------------------------------------------------------------------
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}   # use the rule group's default actions
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # ---------------------------------------------------------------------------
  # Rule 2: Known Bad Inputs (Log4Shell, Spring4Shell etc.)
  # ---------------------------------------------------------------------------
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # ---------------------------------------------------------------------------
  # Rule 3: AWS IP Reputation List (known malicious IPs)
  # ---------------------------------------------------------------------------
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationListMetric"
      sampled_requests_enabled   = true
    }
  }

  # ---------------------------------------------------------------------------
  # Rule 4: Rate Limiting per IP
  # ---------------------------------------------------------------------------
  # Blocks IPs that send more than 2000 requests in 5 minutes.
  # Protects against DDoS and brute force attacks.
  # Adjust the limit based on your expected traffic.
  # ---------------------------------------------------------------------------
  rule {
    name     = "RateLimitPerIP"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000    # requests per 5 minutes per IP
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitPerIPMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf-metric"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project_name}-waf"
  }
}
