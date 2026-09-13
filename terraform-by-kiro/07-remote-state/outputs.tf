output "app_bucket_name" {
  description = "Name of the app S3 bucket"
  value       = aws_s3_bucket.app_bucket.bucket
}

output "app_bucket_arn" {
  description = "ARN of the app S3 bucket"
  value       = aws_s3_bucket.app_bucket.arn
}
