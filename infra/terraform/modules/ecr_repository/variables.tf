variable "name" {
  description = "ECR repository name"
  type        = string
}

variable "force_delete" {
  description = "Allow Terraform to delete the repository even if images exist"
  type        = bool
  default     = true
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "image_tag_mutability" {
  description = "Whether tags are mutable"
  type        = string
  default     = "MUTABLE"
}

variable "tags" {
  description = "Tags to apply to the repository"
  type        = map(string)
  default     = {}
}