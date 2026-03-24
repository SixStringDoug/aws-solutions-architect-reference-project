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