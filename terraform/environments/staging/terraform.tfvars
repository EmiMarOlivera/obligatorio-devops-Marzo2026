aws_region  = "us-east-1"
environment = "staging"

vpc_name                   = "retailstore-staging-vpc"
vpc_cidr_block             = "10.1.0.0/16"
public_subnet_cidr_blocks  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidr_blocks = ["10.1.3.0/24", "10.1.4.0/24"]
azs                        = ["us-east-1a", "us-east-1b"]

cluster_name = "retailstore-staging-cluster"

app_name          = "retailstore-staging"
container_port    = 8080
app_cpu           = 512
app_memory        = 1024
app_desired_count = 1