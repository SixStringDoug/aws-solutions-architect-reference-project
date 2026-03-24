output "backend_ecr_repository_name" {
  value = try(module.backend_ecr[0].repository_name, null)
}

output "backend_ecr_repository_url" {
  value = try(module.backend_ecr[0].repository_url, null)
}