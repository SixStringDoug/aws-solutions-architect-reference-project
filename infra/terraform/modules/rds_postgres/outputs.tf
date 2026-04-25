output "endpoint" {
  value = (
    var.use_managed_master_password
    ? aws_db_instance.this_managed[0].address
    : aws_db_instance.this_standard[0].address
  )
}

output "port" {
  value = (
    var.use_managed_master_password
    ? aws_db_instance.this_managed[0].port
    : aws_db_instance.this_standard[0].port
  )
}

output "identifier" {
  value = (
    var.use_managed_master_password
    ? aws_db_instance.this_managed[0].identifier
    : aws_db_instance.this_standard[0].identifier
  )
}
