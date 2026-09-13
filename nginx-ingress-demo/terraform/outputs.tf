# =============================================================================
# outputs.tf
# =============================================================================
# Outputs useful values after terraform apply.
# Use these to configure kubectl, Helm, and other tools.
#
# USAGE:
#   terraform output eks_cluster_name
#   terraform output -raw kubeconfig_command
# =============================================================================

output "eks_cluster_name" {
  description = "EKS cluster name — use in kubectl and Helm commands"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  description = "Run this command to configure kubectl to connect to EKS"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "aws_lbc_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller — used in Helm values"
  value       = aws_iam_role.aws_lbc.arn
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN — used in ALB Ingress annotation"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "alb_logs_bucket" {
  description = "S3 bucket name for ALB access logs"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "waf_arn" {
  description = "WAF WebACL ARN — used in ALB Ingress annotation"
  value       = aws_wafv2_web_acl.main.arn
}

output "app_url" {
  description = "Application URL"
  value       = "https://${var.app_subdomain}.${var.domain_name}"
}
