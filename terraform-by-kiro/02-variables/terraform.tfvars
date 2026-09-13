# -----------------------------------------------
# Actual values for variables
# These override the defaults in variables.tf
# -----------------------------------------------

aws_region   = "us-east-1"
project_name = "terraform-by-kiro"
environment  = "dev"

# Easy to have multiple tfvars files for different environments:
# - dev.tfvars
# - prod.tfvars
# - staging.tfvars
#
# - Run with a specific one like this:
#
# terraform apply -var-file="prod.tfvars"
