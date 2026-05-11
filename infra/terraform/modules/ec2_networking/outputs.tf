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