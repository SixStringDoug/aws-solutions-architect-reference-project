variable "name_prefix" { type = string }
variable "environment" { type = string }

variable "vpc_id" {
  description = "VPC ID where the RDS instance and DB security group will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "db_name" {
  type    = string
  default = "tasktracker"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage_gb" {
  type    = number
  default = 20
}

variable "multi_az" {
  type    = bool
  default = false
}

# Optional (cost): uses Secrets Manager behind the scenes
variable "use_managed_master_password" {
  type    = bool
  default = false
}

# Safe default = “no one can connect”
variable "allowed_cidr" {
  type    = string
  default = "0.0.0.0/32"
}

variable "backup_retention_period" {
  description = "Number of days to retain automated RDS backups. Low value is used for cost-controlled dev workloads."
  type        = number
  default     = 1
}