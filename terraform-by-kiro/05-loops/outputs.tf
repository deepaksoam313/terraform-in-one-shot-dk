# -----------------------------------------------
# Outputs for loops demo
# -----------------------------------------------

# count - outputs a list of all bucket names
output "count_bucket_names" {
  description = "Names of buckets created with count"
  value       = [for b in aws_s3_bucket.count_buckets : b.bucket]
}

# for_each with set - outputs a map of key -> bucket name
output "env_bucket_names" {
  description = "Names of buckets created with for_each (set)"
  value       = { for k, b in aws_s3_bucket.env_buckets : k => b.bucket }
}

# for_each with map - outputs a map of key -> bucket name
output "map_bucket_names" {
  description = "Names of buckets created with for_each (map)"
  value       = { for k, b in aws_s3_bucket.map_buckets : k => b.bucket }
}

# security group id
output "web_sg_id" {
  description = "ID of the security group created with dynamic block"
  value       = aws_security_group.web_sg.id
}
