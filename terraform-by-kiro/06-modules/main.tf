# -----------------------------------------------
# 06 - MODULES
# This is the ROOT config — it CALLS the module
# Think of this as the consumer of the blueprint
# -----------------------------------------------

provider "aws" {
  region = "us-east-1"
}

# ----------------------------
# Call the module — 3 times with different inputs
# Syntax: module "<local_name>" { source = "<path>" }
# ----------------------------

# Create a logs bucket (versioning off)
module "logs_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "terraform-by-kiro-logs-2026"
  extra_tags  = { Purpose = "logging" }
}

# Create a backups bucket (versioning on)
module "backups_bucket" {
  source            = "./modules/s3-bucket"
  bucket_name       = "terraform-by-kiro-backups-2026"
  enable_versioning = true
  extra_tags        = { Purpose = "backup" }
}

# Create an assets bucket (versioning off)
module "assets_bucket" {
  source      = "./modules/s3-bucket"
  bucket_name = "terraform-by-kiro-assets-2026"
  extra_tags  = { Purpose = "static-assets" }
}
