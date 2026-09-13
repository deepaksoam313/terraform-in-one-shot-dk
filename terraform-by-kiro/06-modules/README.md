# 06 - Modules

## What you learn here
- What a module is and why it matters
- How to write a reusable module (the blueprint)
- How to call a module from root config (the consumer)
- How to pass inputs to a module and read its outputs

---

## What is a Module?

A module is a **reusable, self-contained block of Terraform config**.

Think of it like a function in programming:
- It takes **inputs** (variables)
- It does some work (creates resources)
- It returns **outputs**

You write it once, call it many times with different inputs.

---

## Folder Structure

```
06-modules/
├── main.tf                        ← root config (calls the module)
├── outputs.tf                     ← root outputs (reads module outputs)
└── modules/
    └── s3-bucket/                 ← the module (the blueprint)
        ├── main.tf                ← resources inside the module
        ├── variables.tf           ← module inputs
        └── outputs.tf             ← module outputs
```

---

## Module Syntax

### Calling a module (root config)
```hcl
module "logs_bucket" {
  source      = "./modules/s3-bucket"   # path to the module
  bucket_name = "my-logs-bucket"        # input variable
}
```

### Reading module outputs (root config)
```hcl
output "logs_arn" {
  value = module.logs_bucket.bucket_arn  # module.<name>.<output>
}
```

---

## Inputs, Outputs and Resources

| File | Role |
|---|---|
| `modules/s3-bucket/variables.tf` | Declares what inputs the module accepts |
| `modules/s3-bucket/main.tf` | Creates resources using those inputs |
| `modules/s3-bucket/outputs.tf` | Exposes values back to the caller |
| `main.tf` (root) | Calls the module with actual values |
| `outputs.tf` (root) | Reads values from module outputs |

---

## Why use modules?

- **Reusability** — write once, use many times
- **Consistency** — every bucket/EC2/VPC follows the same standard
- **Maintainability** — fix the module once, all callers benefit
- **Separation of concerns** — root config stays clean and readable

---

## Community Modules (Terraform Registry)

You don't always have to write your own. Use battle-tested modules:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```
Browse at: https://registry.terraform.io/browse/modules

---

## Files
- `main.tf`                        → root config calling the module 3 times
- `outputs.tf`                     → root outputs reading module outputs
- `modules/s3-bucket/main.tf`      → module resources
- `modules/s3-bucket/variables.tf` → module inputs
- `modules/s3-bucket/outputs.tf`   → module outputs

## Try It
```bash
cd 06-modules
terraform init       # also downloads module
terraform plan
terraform apply
terraform output
terraform destroy
```
