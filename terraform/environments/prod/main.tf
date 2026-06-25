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

  default_tags {
    tags = {
      Project     = "retailstore"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "networking" {
  source = "../../modules/networking"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
  enable_nat_gateway   = var.enable_nat_gateway
}

module "ecr" {
  source = "../../modules/ecr"

  environment          = var.environment
  services             = var.services
  max_image_count      = var.max_image_count
  image_tag_mutability = "IMMUTABLE"
}

data "aws_iam_role" "labrole" {
  name = "LabRole"
}

module "ecs" {
  source = "../../modules/ecs"

  cluster_name = var.cluster_name
  environment  = var.environment
}

locals {
  service_env_vars = {
    orders = [
      { name = "RETAIL_ORDERS_PERSISTENCE_ENDPOINT", value = "postgres.retail.local:5432" },
      { name = "RETAIL_ORDERS_PERSISTENCE_USERNAME",  value = "retail_user" },
      { name = "RETAIL_ORDERS_PERSISTENCE_PASSWORD",  value = "retail_pass" },
      { name = "RETAIL_ORDERS_PERSISTENCE_NAME",      value = "orders" }
    ]
    catalog = [
      { name = "RETAIL_CATALOG_PERSISTENCE_PROVIDER",  value = "postgres" },
      { name = "RETAIL_CATALOG_PERSISTENCE_ENDPOINT",  value = "postgres.retail.local:5432" },
      { name = "RETAIL_CATALOG_PERSISTENCE_DB_NAME",   value = "catalogdb" },
      { name = "RETAIL_CATALOG_PERSISTENCE_USER",      value = "retail_user" },
      { name = "RETAIL_CATALOG_PERSISTENCE_PASSWORD",  value = "retail_pass" }
    ]
    cart = [
      { name = "CART_PERSISTENCE_PROVIDER", value = "postgres" },
      { name = "CART_POSTGRES_HOST",        value = "postgres.retail.local" },
      { name = "CART_POSTGRES_PORT",        value = "5432" },
      { name = "CART_POSTGRES_DB",          value = "cartdb" },
      { name = "CART_POSTGRES_USER",        value = "retail_user" },
      { name = "CART_POSTGRES_PASSWORD",    value = "retail_pass" }
    ]
  }
}

module "app" {
  for_each = toset(var.services)
  source   = "../../modules/ecs_service"

  app_name                = each.value
  environment             = var.environment
  cluster_id              = module.ecs.cluster_id
  vpc_id                  = module.networking.vpc_id
  public_subnet_ids       = module.networking.public_subnet_ids
  private_subnet_ids      = module.networking.private_subnet_ids
  container_image         = "${module.ecr.repository_urls[each.value]}:latest"
  task_execution_role_arn = data.aws_iam_role.labrole.arn
  task_role_arn           = data.aws_iam_role.labrole.arn
  cpu                     = var.app_cpu
  memory                  = var.app_memory
  desired_count           = var.app_desired_count
  aws_region              = var.aws_region
  environment_variables   = lookup(local.service_env_vars, each.value, [])
}