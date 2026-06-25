variable "environment" {
  description = "Nombre del ambiente"
  type        = string
}

variable "aws_region" {
  description = "Región AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDRs de las subnets públicas"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs de las subnets privadas"
  type        = list(string)
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway para subnets privadas"
  type        = bool
  default     = true
}

variable "services" {
  description = "Lista de microservicios con repositorio ECR"
  type        = list(string)
  default     = ["ui", "catalog", "cart", "checkout", "orders", "admin", "postgres"]
}

variable "max_image_count" {
  description = "Máximo de imágenes ECR a retener por repositorio"
  type        = number
  default     = 15
}


variable "cluster_name" {
  description = "Nombre del cluster ECS del ambiente"
  type        = string
}

variable "app_cpu" {
  description = "CPU asignada a la tarea ECS Fargate"
  type        = number
}

variable "app_memory" {
  description = "Memoria en MB asignada a la tarea ECS Fargate"
  type        = number
}

variable "app_desired_count" {
  description = "Cantidad deseada de tareas ECS en ejecucion"
  type        = number
}