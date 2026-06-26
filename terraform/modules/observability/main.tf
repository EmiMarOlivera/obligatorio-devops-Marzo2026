locals {
  tags = {
    Environment = var.environment
    Project     = "retailstore"
    ManagedBy   = "terraform"
  }
}

# SNS Topic: canal de notificaciones. Las alarmas publican mensajes aqui
# y SNS los reenvía a todos los suscriptores (en este caso, la Lambda).
resource "aws_sns_topic" "alerts" {
  name = "retailstore-${var.environment}-alerts"
  tags = local.tags
}

# Empaqueta el codigo Python en un ZIP para subirlo a Lambda.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/alert_handler.py"
  output_path = "${path.module}/lambda/alert_handler.zip"
}

# Funcion Lambda: el componente serverless del proyecto.
# Se ejecuta solo cuando SNS la invoca (cuando dispara una alarma).
# No corre permanentemente — escala a cero cuando no hay alertas.
resource "aws_lambda_function" "alert_handler" {
  function_name    = "retailstore-${var.environment}-alert-handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"
  handler          = "alert_handler.handler"
  role             = var.labrole_arn
  timeout          = 30

  tags = local.tags
}

# Permiso para que SNS pueda invocar la Lambda.
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

# Suscripcion: conecta SNS con Lambda.
# Cada mensaje que llega al Topic dispara la funcion Lambda.
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alert_handler.arn
}

# Alarma 1: CPU del servicio checkout supera el 70% durante 10 minutos.
# Metricas de ECS estan en el namespace AWS/ECS con dimensiones ClusterName + ServiceName.
resource "aws_cloudwatch_metric_alarm" "checkout_cpu_high" {
  alarm_name          = "checkout-cpu-high-${var.environment}"
  alarm_description   = "CPU del servicio checkout supera el 70% por 2 periodos de 5 minutos"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = "checkout"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.tags
}

# Alarma 2: Errores HTTP 5xx en el ALB del servicio checkout.
# 5xx significa que el servidor fallo (no el cliente). Mas de 5 en 5 minutos
# indica un problema real en el servicio de pago.
resource "aws_cloudwatch_metric_alarm" "checkout_5xx_errors" {
  alarm_name          = "checkout-5xx-errors-${var.environment}"
  alarm_description   = "Errores HTTP 5xx en el ALB de checkout superan 5 en 5 minutos"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.checkout_alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.tags
}

# Dashboard de CloudWatch con los tres pilares: CPU (rendimiento),
# Memoria (capacidad), y Errores 5xx (disponibilidad).
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "retailstore-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "CPU por Servicio ECS (%)"
          view    = "timeSeries"
          period  = 300
          region  = "us-east-1"
          metrics = [
            for svc in var.services :
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", svc]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Memoria por Servicio ECS (%)"
          view    = "timeSeries"
          period  = 300
          region  = "us-east-1"
          metrics = [
            for svc in var.services :
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, "ServiceName", svc]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Errores 5xx - Checkout ALB"
          view    = "timeSeries"
          period  = 300
          region  = "us-east-1"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.checkout_alb_arn_suffix]
          ]
        }
      },
      {
        type   = "alarm"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Estado de Alarmas"
          alarms = [
            aws_cloudwatch_metric_alarm.checkout_cpu_high.arn,
            aws_cloudwatch_metric_alarm.checkout_5xx_errors.arn
          ]
        }
      }
    ]
  })
}
