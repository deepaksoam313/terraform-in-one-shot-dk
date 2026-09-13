# =============================================================================
# vpc.tf
# =============================================================================
# Creates the network foundation for the entire setup.
#
# ARCHITECTURE:
#
#   VPC (10.0.0.0/16)
#   ├── Public Subnets  (10.0.101.0/24, 10.0.102.0/24)  ← ALB lives here
#   │   └── Internet Gateway attached
#   ├── Private Subnets (10.0.1.0/24, 10.0.2.0/24)      ← EKS nodes live here
#   │   └── NAT Gateway (nodes can reach internet, internet can't reach nodes)
#   └── NAT Gateway (in public subnet, used by private subnet)
#
# WHY PUBLIC/PRIVATE SPLIT?
#   - ALB must be in public subnet to receive internet traffic
#   - EKS nodes in private subnet = more secure (no direct internet exposure)
#   - NAT Gateway lets nodes pull docker images, AWS API calls etc.
#
# SUBNET TAGS:
#   - kubernetes.io/role/elb = 1          → tells AWS LBC to use for ALB
#   - kubernetes.io/role/internal-elb = 1 → tells AWS LBC to use for internal LB
#   - kubernetes.io/cluster/<name> = shared → required for EKS to discover subnets
# =============================================================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  # ---------------------------------------------------------------------------
  # NAT Gateway
  # ---------------------------------------------------------------------------
  # Allows private subnet resources (EKS nodes) to reach the internet
  # for pulling images, AWS API calls etc. — but internet cannot initiate
  # connections to them.
  # single_nat_gateway = true saves cost in non-prod.
  # For prod, use one_nat_gateway_per_az = true for HA.
  # ---------------------------------------------------------------------------
  enable_nat_gateway     = true
  single_nat_gateway     = false           # prod: one per AZ for HA
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true              # required for EKS
  enable_dns_support   = true

  # ---------------------------------------------------------------------------
  # Subnet Tags — CRITICAL for EKS and AWS Load Balancer Controller
  # ---------------------------------------------------------------------------
  # Without these tags, AWS LBC cannot discover which subnets to place the ALB in.
  # ---------------------------------------------------------------------------
  public_subnet_tags = {
    "kubernetes.io/role/elb"                        = 1
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"               = 1
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  }

  tags = {
    Name = "${var.project_name}-vpc"
  }
}
