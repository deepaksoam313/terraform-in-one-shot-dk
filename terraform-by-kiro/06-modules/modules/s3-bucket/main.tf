# -----------------------------------------------
# MODULE: s3-bucket
# A reusable module to create an S3 bucket
# This is the module DEFINITION (the blueprint)
# -----------------------------------------------

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = merge(
    {
      Name      = var.bucket_name
      ManagedBy = "Terraform"
    },
    var.extra_tags
  )
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}
