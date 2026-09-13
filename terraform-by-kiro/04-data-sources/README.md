# 04 - Data Sources

## What you learn here
- What a `data` block is
- How to read existing infrastructure without managing it
- How to reference data source values in resources

## Key Concept

### Data Source vs Resource

| | `resource` | `data` |
|---|---|---|
| Purpose | **Create** new infrastructure | **Read** existing infrastructure |
| Manages lifecycle | Yes (create/update/destroy) | No (read-only) |
| Syntax | `resource "aws_vpc" "x" {}` | `data "aws_vpc" "x" {}` |
| Reference | `aws_vpc.x.id` | `data.aws_vpc.x.id` |

### Data Block Syntax
```hcl
data "aws_vpc" "default" {
  default = true
}
```
- `aws_vpc`  → the data source type
- `default`  → your local name for it
- `default = true` → filter to find the default VPC

### Referencing a Data Source
Always prefix with `data.`:
```
data.<type>.<local_name>.<attribute>
```
Example:
```hcl
data.aws_vpc.default.id
data.aws_availability_zones.available.names
data.aws_ami.amazon_linux.id
```

## Real World Use Cases
- Fetch the default VPC to deploy resources into it
- Get the latest AMI ID so you don't hardcode it
- Look up available AZs dynamically
- Find an existing security group, subnet, or certificate by name/tag

## Files
- `main.tf`    → provider + 3 data sources + S3 resource using data
- `outputs.tf` → outputs showing fetched values

## Try It
```bash
cd 04-data-sources
terraform init
terraform plan
terraform apply
terraform output        # see the fetched VPC id, AZs, AMI id
terraform destroy
```
