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

# -------------------------------------------------------------------
# S3 Bucket para almacenar el estado de Terraform
# El estado es el archivo que Terraform usa para saber qué recursos
# ya existen en la nube. Al guardarlo en S3, todos los integrantes
# del equipo trabajan sobre el mismo estado.
# -------------------------------------------------------------------
resource "aws_s3_bucket" "tfstate" {
  bucket = var.bucket_name

  tags = {
    Project   = "retailstore"
    ManagedBy = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

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