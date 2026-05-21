terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket = "tf-state-terra-deepak"
    key = "dev/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "tf_state_lock_dynamodb"
  }
}

provider "aws" {
  region = "ap-south-1"

}

