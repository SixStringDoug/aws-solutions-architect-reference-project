variable "name_prefix" { type = string }
variable "environment" { type = string }

variable "enabled" {
  type    = bool
  default = false
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Subnets to place instances into (public subnets for this phase)."
  type        = list(string)
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "allow_ssh" {
  type    = bool
  default = false
}

variable "ssh_cidr" {
  description = "Your public IP /32 if you ever temporarily enable SSH."
  type        = string
  default     = "0.0.0.0/32"
}

variable "allow_http" {
  description = "Allow inbound HTTP app traffic on port 8080"
  type        = bool
  default     = false
}

variable "http_cidr" {
  description = "CIDR allowed to reach the app on port 8080"
  type        = string
  default     = "0.0.0.0/0"
}

variable "user_data" {
  description = "User data script for EC2 bootstrap"
  type        = string
  default     = null
}

variable "artifact_bucket_name" {
  description = "S3 bucket containing the application JAR"
  type        = string
}

variable "db_name" {
  description = "Application database name"
  type        = string
}

variable "ssm_parameter_paths" {
  description = "SSM parameter paths for DB configuration"
  type = object({
    db_host     = string
    db_port     = string
    db_username = string
    db_password = string
  })
}

variable "enable_alb" {
  description = "Create an Application Load Balancer for EC2 application access"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch retention period for EC2 logs"
  type        = number
  default     = 7
}