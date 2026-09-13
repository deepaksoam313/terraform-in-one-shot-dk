# -----------------------------------------------
# 02 - VARIABLES
# Concepts: input variables, locals, tfvars
# -----------------------------------------------


# Locals - computed values built from variables

resource "aws_s3_bucket" "learning_bucket" {
  bucket = local.bucket_name
  tags   = local.common_tags
}
