output "database_endpoint" {
  value = local.host
}

output "database_db_name" {
  value = aws_db_instance.database.db_name
}

output "database_db_user" {
  value     = aws_db_instance.database.username
  sensitive = true
}

output "database_password" {
  value     = aws_db_instance.database.password
  sensitive = true
}
