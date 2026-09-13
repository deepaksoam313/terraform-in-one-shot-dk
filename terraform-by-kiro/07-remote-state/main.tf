# -----------------------------------------------
# 07 - REMOTE STATE
# Concepts: S3 backend, state locking with DynamoDB
#
# By default Terraform stores state in a local
# terraform.tfstate file. That is fine for learning
# but dangerous in teams — someone can overwrite it.
#
# Remote state stores it in S3 so:
#   - Everyone on the team reads the same state
#   - DynamoDB prevents two applies at the same time
# -----------------------------------------------

terraform {
  backend "s3" {
    bucket         = "terraform-by-kiro-remote-state-2026"  # S3 bucket from bootstrap
    key            = "07-remote-state/terraform.tfstate"    # path inside the bucket
    region         = "us-east-1"
    dynamodb_table = "terraform-by-kiro-state-lock"         # DynamoDB table from bootstrap
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "terraform-by-kiro-app-remote-2026"

  tags = {
    Name      = "app-bucket"
    ManagedBy = "Terraform"
  }
}
