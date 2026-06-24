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

  environment     = var.environment
  services        = var.services
  max_image_count = var.max_image_count
}

data "aws_iam_role" "labrole" {
  name = "LabRole"
}

module "ecs" {
  source = "../../modules/ecs"

  cluster_name = var.cluster_name
  environment  = var.environment
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
}

module "observability" {
  source = "../../modules/observability"

  environment             = var.environment
  cluster_name            = var.cluster_name
  services                = var.services
  labrole_arn             = data.aws_iam_role.labrole.arn
  checkout_alb_arn_suffix = module.app["checkout"].alb_arn_suffix
}