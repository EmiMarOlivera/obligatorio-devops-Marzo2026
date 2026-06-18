variable "environment" {
  description = "Nombre del ambiente (dev, staging, prod)"
  type        = string
}

variable "services" {
  description = "Lista de microservicios para los que se crea un repositorio ECR"
  type        = list(string)
  default     = ["ui", "catalog", "cart", "checkout", "orders", "admin"]
}

variable "image_tag_mutability" {
  description = "MUTABLE permite sobreescribir tags (útil en dev). IMMUTABLE garantiza reproducibilidad (recomendado en prod)."
  type        = string
  default     = "MUTABLE"
}

variable "max_image_count" {
  description = "Número máximo de imágenes a retener por repositorio. Las más antiguas se eliminan automáticamente."
  type        = number
  default     = 10
}