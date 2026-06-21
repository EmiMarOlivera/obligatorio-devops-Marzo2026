# El backend remoto indica a Terraform dónde guardar el archivo de estado.
# IMPORTANTE: reemplazar "retailstore-tfstate-REEMPLAZAR" con el nombre
# real del bucket creado al correr el bootstrap.
# Este bloque NO admite variables — debe ser hardcodeado.
terraform {
  backend "s3" {
    bucket         = "retailstore-tfstate-fne26"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "retailstore-tfstate-lock"
    encrypt        = true
  }
}