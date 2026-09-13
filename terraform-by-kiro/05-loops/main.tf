# -----------------------------------------------
# 05 - LOOPS
# Concepts: count, for_each (set + map), dynamic blocks
# -----------------------------------------------

provider "aws" {
  region = "us-east-1"
}

# -----------------------------------------------
# 1. COUNT
# Use when you want N identical resources
# count.index gives 0, 1, 2 ...
# -----------------------------------------------
resource "aws_s3_bucket" "count_buckets" {
  count  = 3
  bucket = "terraform-by-kiro-count-${count.index}-2026"

  tags = {
    Name  = "count-bucket-${count.index}"
    Index = count.index
  }
}

# -----------------------------------------------
# 2. FOR_EACH with a set of strings
# Use when you have unique named resources
# each.key = the value from the set
# -----------------------------------------------
resource "aws_s3_bucket" "env_buckets" {
  for_each = toset(["dev", "staging", "prod"])

  bucket = "terraform-by-kiro-${each.key}-env-2026"

  tags = {
    Name        = "env-bucket-${each.key}"
    Environment = each.key
  }
}

# -----------------------------------------------
# 3. FOR_EACH with a map
# Use when each resource needs different config values
# each.key = map key, each.value = map value
# -----------------------------------------------
variable "buckets_map" {
  description = "Map of bucket name to environment label"
  default = {
    logs    = "logging"
    backups = "backup"
    assets  = "static"
  }
}

resource "aws_s3_bucket" "map_buckets" {
  for_each = var.buckets_map

  bucket = "terraform-by-kiro-${each.key}-2026"

  tags = {
    Name    = each.key
    Purpose = each.value
  }
}

# -----------------------------------------------
# 4. DYNAMIC BLOCK
# Use when a resource has a repeatable nested block
# Here: security group with dynamic ingress rules
# -----------------------------------------------
variable "ingress_rules" {
  description = "Map of ingress rules for the security group"
  default = {
    http  = { port = 80,  cidr = "0.0.0.0/0" }
    https = { port = 443, cidr = "0.0.0.0/0" }
    ssh   = { port = 22,  cidr = "10.0.0.0/8" }
  }
}

resource "aws_security_group" "web_sg" {
  name        = "terraform-by-kiro-web-sg"
  description = "Web security group with dynamic ingress rules"

  # dynamic block loops over ingress_rules map
  # and generates one ingress block per entry
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = [ingress.value.cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "web-sg"
    ManagedBy = "Terraform"
  }
}
