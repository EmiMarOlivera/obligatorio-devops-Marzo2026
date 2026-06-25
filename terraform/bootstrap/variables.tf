variable "aws_region" {
  description = "Región AWS donde se despliega la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para el bloqueo del estado de Terraform"
  type        = string
  default     = "retailstore-tfstate-lock"
}
