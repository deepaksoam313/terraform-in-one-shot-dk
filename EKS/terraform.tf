terraform{
  required_providers{
    aws ={
      source ="hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

locals {
  region          = "ap-south-1"
  name            = "my-eks-cluster"
  vpc_cidr        = "10.0.0.0/16"
  azs             = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  intra_subnets   = ["10.0.5.0/24", "10.0.6.0/24"]

  tags = {
    Project = local.name
  }
}

provider "aws" {
  region= local.region
}