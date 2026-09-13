# -----------------------------------------------
# 01 - BASICS
# Concepts: provider, resource block
# We create a simple S3 bucket using AWS provider
# -----------------------------------------------

# Provider block - tells Terraform which cloud to use
provider "aws" {
  region = "us-east-1"
}

# Resource block - defines actual infrastructure
# Syntax: resource "<provider_resource_type>" "<local_name>" {}
resource "aws_s3_bucket" "my_first_bucket" {
  bucket = "terraform-by-kiro-basics-demo-2026"

  tags = {
    Name        = "MyFirstBucket"
    Environment = "Learning"
    ManagedBy   = "Terraform"
  }
}
