variable "aws_region" {
  description = "Region de AWS donde se desplegara la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Nombre del ambiente de despliegue, por ejemplo: dev, staging o prod"
  type        = string
}

variable "vpc_cidr" {
  description = "Bloque CIDR principal para la VPC del ambiente"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Bloques CIDR para las subredes publicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Bloques CIDR para las subredes privadas"
  type        = list(string)
}

variable "azs" {
  description = "Zonas de disponibilidad donde se crearan las subredes"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "enable_nat_gateway" {
  description = "Indica si se deben crear NAT Gateways para que las subredes privadas tengan salida a internet"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Nombre del cluster ECS del ambiente"
  type        = string
}

variable "app_name" {
  description = "Nombre de la aplicacion desplegada en ECS"
  type        = string
  default     = "retailstore"
}

variable "container_port" {
  description = "Puerto expuesto por el contenedor de la aplicacion"
  type        = number
  default     = 8080
}

variable "app_cpu" {
  description = "CPU asignada a la tarea ECS Fargate"
  type        = number
  default     = 256
}

variable "app_memory" {
  description = "Memoria en MB asignada a la tarea ECS Fargate"
  type        = number
  default     = 512
}

variable "app_desired_count" {
  description = "Cantidad deseada de tareas ECS en ejecucion"
  type        = number
  default     = 1
}