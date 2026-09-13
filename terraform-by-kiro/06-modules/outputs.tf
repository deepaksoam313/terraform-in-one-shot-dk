# -----------------------------------------------
# Root outputs — consuming module outputs
# Reference format: module.<local_name>.<output_name>
# -----------------------------------------------

output "logs_bucket_arn" {
  description = "ARN of the logs bucket"
  value       = module.logs_bucket.bucket_arn
}

output "backups_bucket_arn" {
  description = "ARN of the backups bucket"
  value       = module.backups_bucket.bucket_arn
}

output "assets_bucket_arn" {
  description = "ARN of the assets bucket"
  value       = module.assets_bucket.bucket_arn
}
