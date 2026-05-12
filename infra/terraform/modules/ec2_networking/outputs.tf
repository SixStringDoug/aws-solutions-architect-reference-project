output "security_group_id" {
  value       = try(aws_security_group.ec2[0].id, null)
  description = "EC2 security group id"
}

output "instance_ids" {
  value       = [for i in aws_instance.this : i.id]
  description = "EC2 instance ids"
}

output "alb_dns_name" {
  value       = try(aws_lb.ec2_app[0].dns_name, null)
  description = "DNS name of the EC2 Application Load Balancer"
}

output "alb_security_group_id" {
  value       = try(aws_security_group.alb[0].id, null)
  description = "Security group ID of the EC2 Application Load Balancer"
}

output "target_group_arn" {
  value       = try(aws_lb_target_group.ec2_app[0].arn, null)
  description = "Target group ARN for EC2 application instances"
}

output "cloudwatch_log_group_name" {
  value       = try(aws_cloudwatch_log_group.ec2[0].name, null)
  description = "CloudWatch log group for EC2 bootstrap and application logs"
}

output "ec2_status_check_alarm_names" {
  value       = [for alarm in aws_cloudwatch_metric_alarm.ec2_status_check_failed : alarm.alarm_name]
  description = "CloudWatch alarm names for EC2 instance status checks"
}

output "alb_unhealthy_hosts_alarm_name" {
  value       = try(aws_cloudwatch_metric_alarm.ec2_alb_unhealthy_hosts[0].alarm_name, null)
  description = "CloudWatch alarm name for ALB unhealthy EC2 targets"
}

output "alb_target_5xx_alarm_name" {
  value       = try(aws_cloudwatch_metric_alarm.ec2_alb_target_5xx[0].alarm_name, null)
  description = "CloudWatch alarm name for ALB target 5XX errors"
}