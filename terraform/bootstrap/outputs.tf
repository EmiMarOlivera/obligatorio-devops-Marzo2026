output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB de bloqueo"
  value       = aws_dynamodb_table.tfstate_lock.name
}
