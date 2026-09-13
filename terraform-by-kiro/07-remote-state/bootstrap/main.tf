# -----------------------------------------------
# BOOTSTRAP - Run this ONCE before everything else
# Creates the S3 bucket and DynamoDB table
# that will store and lock your Terraform state
# -----------------------------------------------

provider "aws" {
  region = "us-east-1"
}

# S3 bucket to store the terraform.tfstate file
resource "aws_s3_bucket" "tf_state" {
  bucket = "terraform-by-kiro-remote-state-2026"

  # Prevent accidental deletion of state bucket
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = "terraform-state-bucket"
    ManagedBy = "Terraform"
  }
}

# Enable versioning so you can recover old state files
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption on the state bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access to the state bucket
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
# Prevents two people/pipelines running terraform apply at the same time
resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-by-kiro-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "terraform-state-lock"
    ManagedBy = "Terraform"
  }
}
