# 02 - Variables

## What you learn here
- Input variables (`variable` block)
- Locals (`locals` block)
- How to use `terraform.tfvars` to set values
- Difference between `var.name` and `local.name`

## Key Concepts

### Input Variable
Declared in `variables.tf`, value provided by user via `terraform.tfvars` or CLI.
```hcl
variable "environment" {
  type    = string
  default = "dev"
}
```
Reference it as: `var.environment`

### Locals
Computed inside the config. Cannot be set by the user.
Great for combining variables or defining reusable expressions.
```hcl
locals {
  bucket_name = "${var.project_name}-${var.environment}-2026"
}
```
Reference it as: `local.bucket_name`

### terraform.tfvars
Automatically loaded by Terraform. Overrides variable defaults.
```hcl
environment = "prod"
```

## When to use what

| Situation                        | Use         |
|----------------------------------|-------------|
| Simple value set by user         | `var.name`  |
| Value built by combining vars    | `local.name`|
| Value reused in many places      | `local.name`|
| Value user should override       | `var.name`  |

## Files
- `main.tf`           → provider + S3 resource using locals
- `variables.tf`      → variable declarations
- `terraform.tfvars`  → actual variable values

## Try It
```bash
cd 02-variables
terraform init
terraform plan
terraform apply
terraform destroy
```

## Override a variable from CLI (no tfvars needed)
```bash
terraform apply -var="environment=prod"
```

## Use a different tfvars file
```bash
terraform apply -var-file="prod.tfvars"
```
