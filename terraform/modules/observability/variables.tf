variable "environment" {
  description = "Nombre del ambiente"
  type        = string
}

variable "cluster_name" {
  description = "Nombre del cluster ECS donde corren los servicios"
  type        = string
}

variable "services" {
  description = "Lista de microservicios (para el dashboard)"
  type        = list(string)
}

variable "labrole_arn" {
  description = "ARN del LabRole usado como execution role de Lambda"
  type        = string
}

variable "checkout_alb_arn_suffix" {
  description = "Sufijo del ARN del ALB de checkout, necesario para la metrica de errores 5xx"
  type        = string
}

variable "aws_region" {
  description = "Región AWS donde se despliega el módulo"
  type        = string
  default     = "us-east-1"
}
