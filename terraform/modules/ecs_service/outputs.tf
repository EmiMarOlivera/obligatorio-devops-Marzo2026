output "alb_dns_name" {
  description = "DNS publico del Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN del Target Group asociado al servicio ECS"
  value       = aws_lb_target_group.main.arn
}

output "ecs_service_name" {
  description = "Nombre del servicio ECS creado"
  value       = aws_ecs_service.main.name
}

output "ecs_service_id" {
  description = "ID del servicio ECS creado"
  value       = aws_ecs_service.main.id
}

output "task_definition_arn" {
  description = "ARN de la Task Definition usada por el servicio ECS"
  value       = aws_ecs_task_definition.main.arn
}

output "ecs_tasks_security_group_id" {
  description = "ID del Security Group asociado a las tareas ECS"
  value       = aws_security_group.ecs_tasks.id
}

output "alb_security_group_id" {
  description = "ID del Security Group asociado al ALB"
  value       = aws_security_group.alb.id
}