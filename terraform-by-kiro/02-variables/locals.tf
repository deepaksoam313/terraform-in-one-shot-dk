# Locals are computed values — not set by the user
locals {
  bucket_name = "${var.project_name}-${var.environment}-2026"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
