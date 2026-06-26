output "sns_topic_arn" {
  description = "ARN del SNS Topic de alertas"
  value       = aws_sns_topic.alerts.arn
}

output "lambda_function_name" {
  description = "Nombre de la funcion Lambda"
  value       = aws_lambda_function.alert_handler.function_name
}

output "cpu_alarm_arn" {
  description = "ARN de la alarma de CPU del checkout"
  value       = aws_cloudwatch_metric_alarm.checkout_cpu_high.arn
}

output "errors_alarm_arn" {
  description = "ARN de la alarma de errores 5xx del checkout"
  value       = aws_cloudwatch_metric_alarm.checkout_5xx_errors.arn
}

output "dashboard_url" {
  description = "URL del dashboard de CloudWatch"
  value       = "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}
