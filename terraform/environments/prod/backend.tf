# IMPORTANTE: reemplazar "retailstore-tfstate-REEMPLAZAR" con el nombre
# real del bucket creado al correr el bootstrap.
terraform {
  backend "s3" {
    bucket         = "retailstore-tfstate-REEMPLAZAR"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "retailstore-tfstate-lock"
    encrypt        = true
  }
}