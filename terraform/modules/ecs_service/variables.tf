variable "app_name" {
  description = "Nombre de la aplicacion o servicio ECS"
  type        = string
}

variable "environment" {
  description = "Nombre del ambiente de despliegue"
  type        = string
}

variable "cluster_id" {
  description = "ID del cluster ECS donde se ejecuta el servicio"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde se despliegan el ALB y las tareas ECS"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs de las subnets publicas donde se ubica el ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas donde se ejecutan las tareas ECS"
  type        = list(string)
}

variable "container_image" {
  description = "URL completa de la imagen Docker a ejecutar en ECS"
  type        = string
}

variable "task_execution_role_arn" {
  description = "ARN del rol IAM usado por ECS para descargar imagenes y enviar logs"
  type        = string
}

variable "task_role_arn" {
  description = "ARN del rol IAM asumido por la aplicacion dentro del contenedor"
  type        = string
  default     = null
}

variable "container_port" {
  description = "Puerto expuesto por el contenedor"
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "CPU asignada a la tarea Fargate"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memoria en MB asignada a la tarea Fargate"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Cantidad deseada de tareas ECS en ejecucion"
  type        = number
  default     = 1
}

variable "aws_region" {
  description = "Region AWS donde se despliega el servicio"
  type        = string
  default     = "us-east-1"
}

variable "health_check_path" {
  description = "Path usado por el ALB para verificar la salud del servicio"
  type        = string
  default     = "/health"
}

variable "environment_variables" {
  description = "Variables de entorno a inyectar en el contenedor"
  type        = list(object({ name = string, value = string }))
  default     = []
}