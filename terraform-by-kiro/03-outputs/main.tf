# -----------------------------------------------
# 03 - OUTPUTS
# Concepts: output block, resource attributes
# -----------------------------------------------

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "demo" {
  bucket = "terraform-by-kiro-outputs-demo-2026"

  tags = {
    Name      = "outputs-demo"
    ManagedBy = "Terraform"
  }
}
