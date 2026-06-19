output "vpc_id" {
  description = "ID de la VPC del ambiente staging"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs de las subnets públicas"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs de las subnets privadas"
  value       = module.networking.private_subnet_ids
}

output "ecr_repository_urls" {
  description = "URLs de los repositorios ECR por servicio (usar en docker push)"
  value       = module.ecr.repository_urls
}