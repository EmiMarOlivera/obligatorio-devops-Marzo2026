variable "aws_region" {
  description = "Región AWS donde se crea el bucket"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Nombre del bucket S3 para el estado de Terraform. Debe ser globalmente único en todo AWS."
  type        = string
}

variable "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para el bloqueo del estado de Terraform"
  type        = string
  default     = "retailstore-tfstate-lock"
}
