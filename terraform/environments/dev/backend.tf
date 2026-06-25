# El bucket se pasa en tiempo de `terraform init` desde el pipeline:
#   terraform init -backend-config="bucket=$TF_BACKEND_BUCKET"
# Esto evita hardcodear el nombre del bucket, que es globalmente único en AWS.
terraform {
  backend "s3" {
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "retailstore-tfstate-lock"
    encrypt        = true
  }
}