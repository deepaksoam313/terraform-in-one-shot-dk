# 01 - Basics

## What you learn here
- What a `provider` block is
- What a `resource` block is
- The core Terraform workflow

## Key Concepts

### Provider
Tells Terraform which platform to interact with (AWS, GCP, Azure, etc.)
```hcl
provider "aws" {
  region = "us-east-1"
}
```

### Resource
Defines the actual piece of infrastructure you want to create.
Syntax: `resource "<TYPE>" "<LOCAL_NAME>" { ... }`
- TYPE      → e.g. aws_s3_bucket, aws_instance, aws_vpc
- LOCAL_NAME → a name you give it (used to reference it elsewhere)

## Workflow Commands

```bash
# 1. Download providers and initialize the working directory
terraform init

# 2. Preview what Terraform will create/change/destroy
terraform plan

# 3. Actually create the infrastructure
terraform apply

# 4. Tear everything down
terraform destroy
```

## Files
- `main.tf` → provider + resource definition

## Try It
```bash
cd 01-basics
terraform init
terraform plan
terraform apply
terraform destroy
```
