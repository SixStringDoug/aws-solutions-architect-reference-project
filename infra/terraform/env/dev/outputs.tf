output "backend_ecr_repository_name" {
  value = try(module.backend_ecr[0].repository_name, null)
}

output "backend_ecr_repository_url" {
  value = try(module.backend_ecr[0].repository_url, null)
}

output "ec2_alb_dns_name" {
  value = try(module.ec2_networking.alb_dns_name, null)
}

output "ec2_alb_security_group_id" {
  value = try(module.ec2_networking.alb_security_group_id, null)
}

output "ec2_target_group_arn" {
  value = try(module.ec2_networking.target_group_arn, null)
}