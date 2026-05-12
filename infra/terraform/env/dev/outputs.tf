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

output "ec2_cloudwatch_log_group_name" {
  value = try(module.ec2_networking.cloudwatch_log_group_name, null)
}

output "ec2_status_check_alarm_names" {
  value = try(module.ec2_networking.ec2_status_check_alarm_names, [])
}

output "ec2_alb_unhealthy_hosts_alarm_name" {
  value = try(module.ec2_networking.alb_unhealthy_hosts_alarm_name, null)
}

output "ec2_alb_target_5xx_alarm_name" {
  value = try(module.ec2_networking.alb_target_5xx_alarm_name, null)
}