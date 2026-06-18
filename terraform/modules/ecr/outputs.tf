output "repository_urls" {
  description = "URLs de los repositorios ECR, indexadas por nombre de servicio. Se usan en el pipeline para el docker push."
  value       = { for name, repo in aws_ecr_repository.services : name => repo.repository_url }
}

output "repository_arns" {
  description = "ARNs de los repositorios ECR, indexados por nombre de servicio. Se usan para definir permisos IAM."
  value       = { for name, repo in aws_ecr_repository.services : name => repo.arn }
}