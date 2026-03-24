output "security_group_id" {
  value       = try(aws_security_group.ec2[0].id, null)
  description = "EC2 security group id"
}

output "instance_ids" {
  value       = [for i in aws_instance.this : i.id]
  description = "EC2 instance ids"
}