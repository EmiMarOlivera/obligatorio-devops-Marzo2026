environment = "prod"
aws_region  = "us-east-1"

# Networking — prod usa el bloque 10.2.0.0/16
vpc_cidr             = "10.2.0.0/16"
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnet_cidrs = ["10.2.3.0/24", "10.2.4.0/24"]
azs                  = ["us-east-1a", "us-east-1b"]
enable_nat_gateway   = true

# ECR — prod retiene más imágenes y usa tags inmutables (en main.tf)
services        = ["ui", "catalog", "cart", "checkout", "orders", "admin"]
max_image_count = 30

# ECS / App
cluster_name      = "retailstore-prod-cluster"
app_cpu           = 1024
app_memory        = 2048
app_desired_count = 2