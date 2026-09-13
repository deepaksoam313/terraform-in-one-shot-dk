# =============================================================================
# s3.tf
# =============================================================================
# Creates S3 bucket for ALB access logs.
#
# WHY LOG ALB ACCESS TO S3?
#   - Every request to ALB is logged (IP, path, status code, latency)
#   - Useful for debugging 5xx errors, security audits, traffic analysis
#   - Logs are compressed and stored cheaply in S3
#   - Can be queried with Athena for analytics
#   - Required for compliance in many organizations
#
# LOG FORMAT INCLUDES:
#   timestamp, client IP, request (method + path), status code,
#   response time, target IP, user agent, SSL cipher etc.
#
# BUCKET POLICY:
#   ALB needs permission to write logs to S3.
#   The bucket policy grants the AWS ELB service account write access.
#   The ELB account ID is region-specific (hardcoded by AWS).
# =============================================================================

resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.project_name}-alb-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true   # allows terraform destroy to delete bucket with logs

  tags = {
    Name = "${var.project_name}-alb-logs"
  }
}

# Get current AWS account ID (used in bucket name for uniqueness)
data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Block all public access to the logs bucket
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# Lifecycle Policy — auto-delete old logs to save cost
# -----------------------------------------------------------------------------
# Logs older than 90 days are deleted automatically.
# Adjust retention based on your compliance requirements.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

# -----------------------------------------------------------------------------
# Bucket Policy — allow ALB to write logs
# -----------------------------------------------------------------------------
# AWS ELB service has a specific account ID per region.
# This policy grants that account permission to put objects in this bucket.
# -----------------------------------------------------------------------------
data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = data.aws_elb_service_account.main.arn }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.alb_logs.arn}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}
