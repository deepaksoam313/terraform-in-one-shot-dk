# 05 - Loops

## What you learn here
- `count` — create N identical resources
- `for_each` with a set — create named resources from a list
- `for_each` with a map — create resources with different config per item
- `dynamic` block — repeat nested blocks inside a resource

---

## 1. count

Creates N copies of a resource. Use `count.index` to make each unique.

```hcl
resource "aws_s3_bucket" "buckets" {
  count  = 3
  bucket = "my-bucket-${count.index}"
}
```

Reference: `aws_s3_bucket.buckets[0]`, `aws_s3_bucket.buckets[1]` ...

**Downside:** If you remove item at index 1, Terraform shifts indexes and may destroy/recreate others.

---

## 2. for_each with a set

```hcl
resource "aws_s3_bucket" "env_buckets" {
  for_each = toset(["dev", "staging", "prod"])
  bucket   = "my-bucket-${each.key}"
}
```

Reference: `aws_s3_bucket.env_buckets["dev"]`, `aws_s3_bucket.env_buckets["prod"]` ...

**Safer than count** — removing one item only destroys that one resource.

---

## 3. for_each with a map

```hcl
variable "buckets_map" {
  default = {
    logs    = "logging"
    backups = "backup"
  }
}

resource "aws_s3_bucket" "map_buckets" {
  for_each = var.buckets_map
  bucket   = "my-bucket-${each.key}"
  tags     = { Purpose = each.value }
}
```

- `each.key`   → map key (logs, backups)
- `each.value` → map value (logging, backup)

---

## 4. dynamic block

Repeats a nested block inside a resource. Used when a resource accepts multiple blocks of the same type (like ingress rules in a security group).

```hcl
dynamic "ingress" {
  for_each = var.ingress_rules
  content {
    from_port   = ingress.value.port
    to_port     = ingress.value.port
    protocol    = "tcp"
    cidr_blocks = [ingress.value.cidr]
  }
}
```

---

## count vs for_each vs dynamic

| Loop | Where | Use case |
|---|---|---|
| `count` | Resource level | N identical resources |
| `for_each` | Resource level | Named/unique resources |
| `dynamic` | Inside a resource | Repeat nested blocks within one resource |

## Rule of thumb
> Use `for_each` by default. Use `count` only when resources are truly identical. Use `dynamic` for nested repeating blocks.

---

## Files
- `main.tf`    → all 4 loop types with examples
- `outputs.tf` → outputs for each loop result

## Try It
```bash
cd 05-loops
terraform init
terraform plan
terraform apply
terraform output
terraform destroy
```
