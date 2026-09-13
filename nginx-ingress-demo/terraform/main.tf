# =============================================================================
# main.tf
# =============================================================================
# Entry point for Terraform configuration.
# Defines:
#   - Required providers and versions
#   - AWS provider configuration
#   - Remote state backend (S3 + DynamoDB for locking)
#
# FLOW:
#   terraform init  → downloads providers, sets up backend
#   terraform plan  → shows what will be created
#   terraform apply → creates all resources
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }

  # ---------------------------------------------------------------------------
  # Remote State Backend
  # ---------------------------------------------------------------------------
  # Stores terraform.tfstate in S3 instead of locally.
  # Why? So your team can share state and avoid conflicts.
  # DynamoDB table provides state locking — prevents two people running
  # terraform apply at the same time which would corrupt state.
  #
  # NOTE: Create this S3 bucket and DynamoDB table manually BEFORE running
  # terraform init, or use the remote-infra/ folder in this repo.
  # ---------------------------------------------------------------------------
  backend "s3" {
    bucket         = "nginx-ingress-demo-tfstate"   # your S3 bucket name
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "nginx-ingress-demo-tf-lock"   # for state locking
    encrypt        = true                            # encrypt state at rest
  }
}

# -----------------------------------------------------------------------------
# AWS Provider
# -----------------------------------------------------------------------------
# All AWS resources will be created in this region.
# default_tags applies to ALL resources automatically — no need to repeat tags.
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Kubernetes Provider
# -----------------------------------------------------------------------------
# Connects Terraform to your EKS cluster so it can create K8s resources.
# Uses the EKS cluster endpoint and auth token from the eks module output.
# -----------------------------------------------------------------------------
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# -----------------------------------------------------------------------------
# Helm Provider
# -----------------------------------------------------------------------------
# Allows Terraform to install Helm charts into EKS.
# Same auth as Kubernetes provider above.
# -----------------------------------------------------------------------------
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}
