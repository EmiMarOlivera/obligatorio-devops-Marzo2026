variable "environment" {
  description = "Nombre del ambiente donde se crea el cluster ECS"
  type        = string
}

variable "cluster_name" {
  description = "Nombre del cluster ECS"
  type        = string
}

variable "enable_container_insights" {
  description = "Habilita CloudWatch Container Insights para el cluster ECS"
  type        = bool
  default     = true
}