# -----------------------------------------------
# 04 - DATA SOURCES
# Concepts: data block, reading existing infrastructure
# Data sources let you FETCH info about existing resources
# without managing them with Terraform
# -----------------------------------------------

provider "aws" {
  region = "us-east-1"
}

# ----------------------------
# DATA SOURCE - fetch existing VPC (default VPC in your account)
# Syntax: data "<provider_resource_type>" "<local_name>" {}
# ----------------------------
data "aws_vpc" "default" {
  default = true
}

# DATA SOURCE - fetch available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# DATA SOURCE - fetch latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ----------------------------
# Use the data source values in a resource
# Reference format: data.<type>.<local_name>.<attribute>
# ----------------------------
resource "aws_s3_bucket" "demo" {
  bucket = "terraform-by-kiro-datasource-demo-2026"

  tags = {
    Name      = "datasource-demo"
    VPC       = data.aws_vpc.default.id
    ManagedBy = "Terraform"
  }
}
