output "new_sg_with_vpc_name_id" {
  value = module.new_sg_with_vpc_name.id[0]
}

output "new_sg_with_vpc_id" {
  value = module.new_sg_with_vpc_id.id[0]
}

output "new_sg_with_source_group_id" {
  value = module.new_sg_with_sec_group_id.id[0]
}
