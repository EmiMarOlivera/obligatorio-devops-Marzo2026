output "bucket_name" {
  description = "Nombre del bucket S3 creado para el estado de Terraform"
  value       = aws_s3_bucket.tfstate.id
}

output "bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.tfstate.arn
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB de bloqueo"
  value       = aws_dynamodb_table.tfstate_lock.name
}
