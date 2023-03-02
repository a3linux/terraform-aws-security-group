output "id" {
  value       = try(local.id, null)
  description = "IDs on the AWS Security Groups associated with the instance."
}

output "tags" {
  value = local.tags
  description = "Security Group Tags"
}

output "name" {
  value = local.sg_existing ? "" : local.name
  description = "GroupName created"
}

output "arns" {
  description = "ARN of security group"
  value = try(local.arn, null)
}
