# -----------------------------------------------
# Output blocks
# Syntax: output "<name>" { value = <expression> }
# Reference format: <resource_type>.<local_name>.<attribute>
# -----------------------------------------------

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.demo.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.demo.arn
}

output "bucket_region" {
  description = "Region where the bucket is created"
  value       = aws_s3_bucket.demo.region
}
