resource "aws_service_discovery_private_dns_namespace" "retail" {
  name = "retail.local"
  vpc  = module.networking.vpc_id
}

resource "aws_service_discovery_service" "postgres" {
  name = "postgres"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.retail.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

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

  service_registries {
    registry_arn = aws_service_discovery_service.postgres.arn
  }
}
