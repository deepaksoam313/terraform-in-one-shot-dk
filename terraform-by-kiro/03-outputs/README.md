# 03 - Outputs

## What you learn here
- How to define `output` blocks
- How to reference resource attributes
- How to query outputs from the CLI

## Key Concepts

### Output Block
Displays a value after `terraform apply`. Think of it as a `return` statement.
```hcl
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.demo.bucket
}
```

### Resource Attribute Reference
Every resource exposes attributes you can read. Syntax:
```
<resource_type>.<local_name>.<attribute>
```
Examples:
- `aws_s3_bucket.demo.bucket`  → bucket name
- `aws_s3_bucket.demo.arn`     → ARN
- `aws_s3_bucket.demo.region`  → region

## After terraform apply you will see
```
Outputs:

bucket_arn    = "arn:aws:s3:::terraform-by-kiro-outputs-demo-2026"
bucket_name   = "terraform-by-kiro-outputs-demo-2026"
bucket_region = "us-east-1"
```

## CLI Commands for Outputs
```bash
terraform output                   # show all outputs
terraform output bucket_name       # show a specific output
terraform output -json             # show all outputs in JSON format
```

## Files
- `main.tf`    → provider + S3 resource
- `outputs.tf` → output definitions

## Try It
```bash
cd 03-outputs
terraform init
terraform plan
terraform apply
terraform output
terraform destroy
```

## Key Use Case — Modules
Outputs are most powerful when passing values between modules.
For example: a VPC module outputs `vpc_id`, and an EC2 module takes it as input.
We will see this in 06-modules.
