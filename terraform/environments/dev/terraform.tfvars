environment = "dev"
aws_region  = "us-east-1"

# Networking — dev usa el bloque 10.0.0.0/16
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
azs                  = ["us-east-1a", "us-east-1b"]
enable_nat_gateway   = true

# ECR
services        = ["ui", "catalog", "cart", "checkout", "orders", "admin"]
max_image_count = 10