locals {
  tags = {
    Environment = var.environment
    Project     = "retailstore"
    ManagedBy   = "terraform"
  }
}

# Security Group del ALB
# Permite recibir trafico HTTP desde internet en el puerto 80
resource "aws_security_group" "alb" {
  name        = "${var.app_name}-alb-sg"
  description = "Allow HTTP traffic to the application load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.app_name}-alb-sg"
  })
}

# Security Group de las tareas ECS.
# Solo permite trafico desde el Security Group del ALB hacia el puerto del contenedor.

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-tasks-sg"
  description = "Allow traffic from ALB to ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Application traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.app_name}-tasks-sg"
  })
}

# Application Load Balancer publico.
# Vive en subnets publicas para exponer la aplicacion hacia internet.
resource "aws_lb" "main" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = merge(local.tags, {
    Name = "${var.app_name}-alb"
  })
}

# Target Group del ALB.
# Como ECS Fargate usa awsvpc, el target_type debe ser "ip".
resource "aws_lb_target_group" "main" {
  name        = "${var.app_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  # Health check usado por el ALB para saber si las tareas estan sanas.
  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = merge(local.tags, {
    Name = "${var.app_name}-tg"
  })
}

# Listener HTTP del ALB.
# Escucha en el puerto 80 y reenvia el trafico al Target Group.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Log Group de CloudWatch.
# Recibe los logs generados por el contenedor de la task ECS.
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 7

  tags = merge(local.tags, {
    Name = "/ecs/${var.app_name}"
  })
}

# Task Definition Fargate.
# Define como se ejecuta el contenedor: imagen, CPU, memoria, puerto, roles y logs.
resource "aws_ecs_task_definition" "main" {
  family                   = var.app_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.main.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = merge(local.tags, {
    Name = var.app_name
  })
}

# ECS Service.
# Mantiene corriendo la cantidad deseada de tareas Fargate y las registra en el Target Group.
resource "aws_ecs_service" "main" {
  name            = var.app_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  # Las tasks se ejecutan en subnets privadas.
  # No reciben IP publica; salen a internet por NAT si la VPC lo tiene habilitado.
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  # Conecta el ECS Service con el ALB.
  # El ALB envia trafico al container_name/container_port definidos aca.
  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.http
  ]

  tags = merge(local.tags, {
    Name = var.app_name
  })
}