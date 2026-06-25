resource "aws_security_group" "postgres" {
  name        = "postgres-sg"
  description = "Allow PostgreSQL traffic from within the VPC"
  vpc_id      = module.networking.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# NLB interno para que los servicios se conecten a postgres via TCP 5432
# Reemplaza Service Discovery (no disponible en AWS Academy LabRole)
resource "aws_lb" "postgres_nlb" {
  name               = "postgres-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = module.networking.private_subnet_ids
}

resource "aws_lb_target_group" "postgres_nlb" {
  name        = "postgres-nlb-tg"
  port        = 5432
  protocol    = "TCP"
  vpc_id      = module.networking.vpc_id
  target_type = "ip"

  health_check {
    protocol = "TCP"
    port     = 5432
  }
}

resource "aws_lb_listener" "postgres_nlb" {
  load_balancer_arn = aws_lb.postgres_nlb.arn
  port              = 5432
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.postgres_nlb.arn
  }
}

resource "aws_cloudwatch_log_group" "postgres" {
  name              = "/ecs/postgres"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "postgres" {
  family                   = "postgres"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.labrole.arn
  task_role_arn            = data.aws_iam_role.labrole.arn

  container_definitions = jsonencode([{
    name      = "postgres"
    image     = "${module.ecr.repository_urls["postgres"]}:latest"
    essential = true

    portMappings = [{
      containerPort = 5432
      protocol      = "tcp"
    }]

    environment = [
      { name = "POSTGRES_USER",     value = "retail_user" },
      { name = "POSTGRES_PASSWORD", value = "retail_pass" },
      { name = "POSTGRES_DB",       value = "orders" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/postgres"
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "postgres" {
  name            = "postgres"
  cluster         = module.ecs.cluster_id
  task_definition = aws_ecs_task_definition.postgres.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.networking.private_subnet_ids
    security_groups  = [aws_security_group.postgres.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.postgres_nlb.arn
    container_name   = "postgres"
    container_port   = 5432
  }
}
