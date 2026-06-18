aws_region  = "us-east-1"
environment = "dev"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
azs                  = ["us-east-1a", "us-east-1b"]
enable_nat_gateway   = true

cluster_name = "retailstore-dev-cluster"

app_name          = "retailstore-dev"
container_port    = 8080
app_cpu           = 256
app_memory        = 512
app_desired_count = 1