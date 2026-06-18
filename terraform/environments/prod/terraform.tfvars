aws_region  = "us-east-1"
environment = "prod"

vpc_cidr             = "10.2.0.0/16"
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnet_cidrs = ["10.2.3.0/24", "10.2.4.0/24"]
azs                  = ["us-east-1a", "us-east-1b"]
enable_nat_gateway   = true

cluster_name = "retailstore-prod-cluster"

app_name          = "retailstore-prod"
container_port    = 8080
app_cpu           = 1024
app_memory        = 2048
app_desired_count = 2