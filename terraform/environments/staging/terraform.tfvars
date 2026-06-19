environment = "staging"
aws_region  = "us-east-1"

# Networking — staging usa el bloque 10.1.0.0/16
vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.3.0/24", "10.1.4.0/24"]
azs                  = ["us-east-1a", "us-east-1b"]
enable_nat_gateway   = true

# ECR
services        = ["ui", "catalog", "cart", "checkout", "orders", "admin"]
max_image_count = 15