variable "name_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "owner" {
  type = string
}

variable "project" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.10.0/24", "10.10.11.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.20.0/24", "10.10.21.0/24"]
}

variable "enable_nat_gateway" {
  type    = bool
  default = false
}