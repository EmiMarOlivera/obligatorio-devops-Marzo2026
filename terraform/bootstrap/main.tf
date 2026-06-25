terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# El bucket S3 para el estado se crea manualmente una única vez fuera
# de Terraform. El nombre se pasa al pipeline como secreto TF_BACKEND_BUCKET.

# -------------------------------------------------------------------
# DynamoDB Table para bloqueo del estado (state locking)
# Evita que dos personas apliquen cambios al mismo tiempo,
# lo que podría corromper el archivo de estado.
# billing_mode = PAY_PER_REQUEST → sin costo fijo, casi gratuita.
# -------------------------------------------------------------------
resource "aws_dynamodb_table" "tfstate_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project   = "retailstore"
    ManagedBy = "terraform"
  }
}