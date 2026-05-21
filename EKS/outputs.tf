output "vpc_name" {
  value = module.vpc.vpc_id

}

output "vpc_nat_gateways" {
  value = module.vpc.natgw_ids[*]
}

output "vpc_public_route_table"{
  value = module.vpc.public_route_table_ids[*]
}


output "vpc_private_route_table"{
  value = module.vpc.private_route_table_ids[*]
}

output "public_subnet_list" {
  value = module.vpc.public_subnets[*]
}
output "private_subnets" {
  value = module.vpc.private_subnets[*]
}