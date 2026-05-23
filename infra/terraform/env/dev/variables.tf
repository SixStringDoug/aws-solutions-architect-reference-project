variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "project" {
  type    = string
  default = "tasktracker"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "owner" {
  type = string
}

variable "name_prefix" {
  type    = string
  default = "tasktracker-dev"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}

# -----------------------------
# Compute Toggles
# -----------------------------

variable "enable_networking" {
  description = "Master toggle for networking components"
  type        = bool
  default     = false
}

variable "enable_ec2" {
  description = "Enable EC2 compute path (Project 1)"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway (cost-generating resource)"
  type        = bool
  default     = false
}

variable "nat_cost_acknowledged" {
  description = "Explicit acknowledgment that NAT Gateway incurs cost"
  type        = bool
  default     = false
}

variable "ec2_instance_type" {
  description = "EC2 instance type for Project 1"
  type        = string
  default     = "t3.micro"
}

variable "ec2_desired_count" {
  description = "Number of EC2 instances to deploy"
  type        = number
  default     = 1
}

variable "ec2_use_private_subnets" {
  description = "Place EC2 ASG instances in private subnets instead of public subnets"
  type        = bool
  default     = false
}

variable "enable_ec2_alb" {
  description = "Enable Application Load Balancer for EC2 path"
  type        = bool
  default     = false
}

variable "enable_cloudformation" {
  description = "Enable deployment of CloudFormation ECS/Fargate skeleton stack"
  type        = bool
  default     = false
}

variable "enable_ecr" {
  description = "Enable ECR repository for backend container image"
  type        = bool
  default     = false
}

variable "fargate_use_private_subnets" {
  description = "Place Fargate tasks in private subnets instead of public subnets"
  type        = bool
  default     = false
}

variable "fargate_desired_count" {
  description = "Desired number of ECS/Fargate tasks"
  type        = number
  default     = 1
}

variable "fargate_enable_service_auto_scaling" {
  description = "Enable ECS Service Auto Scaling for the Fargate service"
  type        = bool
  default     = false
}

variable "fargate_service_min_capacity" {
  description = "Minimum number of Fargate tasks for ECS Service Auto Scaling"
  type        = number
  default     = 2
}

variable "fargate_service_max_capacity" {
  description = "Maximum number of Fargate tasks for ECS Service Auto Scaling"
  type        = number
  default     = 3
}

variable "fargate_service_cpu_target_value" {
  description = "Target average CPU utilization percentage for Fargate service target tracking"
  type        = number
  default     = 60
}

# -----------------------------
# ECS Container Deployment
# -----------------------------

variable "container_image" {
  description = "Full ECR image URI including tag (used by ECS task definition)"
  type        = string
  default     = ""
}