# -----------------------------------------------
# Output data source values so you can see what was fetched
# -----------------------------------------------

output "default_vpc_id" {
  description = "ID of the default VPC"
  value       = data.aws_vpc.default.id
}

output "default_vpc_cidr" {
  description = "CIDR block of the default VPC"
  value       = data.aws_vpc.default.cidr_block
}

output "available_azs" {
  description = "List of available availability zones"
  value       = data.aws_availability_zones.available.names
}

output "latest_amazon_linux_ami" {
  description = "ID of the latest Amazon Linux 2 AMI"
  value       = data.aws_ami.amazon_linux.id
}
