locals {
  tags = {
    Environment = var.environment
    Project     = "retailstore"
    ManagedBy   = "terraform"
  }
}

# -------------------------------------------------------------------
# Repositorios ECR — uno por microservicio
# for_each itera sobre la lista de servicios y crea un recurso
# independiente para cada uno. El nombre sigue el patrón:
# retailstore-<ambiente>-<servicio>  (ej: retailstore-dev-catalog)
# -------------------------------------------------------------------
resource "aws_ecr_repository" "services" {
  for_each = toset(var.services)

  name                 = "retailstore-${var.environment}-${each.key}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true

  # scan_on_push = true activa el escaneo automático de vulnerabilidades
  # cada vez que se publica una imagen nueva (requisito 5.3 del obligatorio)
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.tags, { Name = each.key })
}

# -------------------------------------------------------------------
# Lifecycle policy — limpia imágenes antiguas automáticamente
# Sin esto, ECR acumula imágenes indefinidamente y aumenta el costo.
# La política elimina imágenes cuando hay más de max_image_count.
# -------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "services" {
  for_each = aws_ecr_repository.services

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retener solo las últimas ${var.max_image_count} imágenes"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}