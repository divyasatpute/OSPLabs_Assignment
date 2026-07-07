##############################################
# ECS Cluster
##############################################

resource "aws_ecs_cluster" "this" {

  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }
}

##############################################
# ECS Task Definition
##############################################

resource "aws_ecs_task_definition" "this" {

  family = "${var.project_name}-${var.environment}"

  network_mode = "awsvpc"

  requires_compatibilities = [
    "FARGATE"
  ]

  cpu    = var.cpu
  memory = var.memory

  execution_role_arn = var.execution_role_arn

  runtime_platform {

    operating_system_family = "LINUX"

    cpu_architecture = "X86_64"

  }

  container_definitions = jsonencode([

    {

      name = var.container_name

      image = var.container_image

      essential = true

      portMappings = [

        {

          containerPort = var.container_port

          hostPort = var.container_port

          protocol = "tcp"

        }

      ]

      logConfiguration = {

        logDriver = "awslogs"

        options = {

          awslogs-group = var.log_group_name

          awslogs-region = var.region

          awslogs-stream-prefix = "ecs"

        }

      }

    }

  ])

  tags = {

    Name = "${var.project_name}-${var.environment}-task"

  }

}

##############################################
# ECS Service
##############################################

resource "aws_ecs_service" "this" {

  name = "${var.project_name}-${var.environment}-service"

  cluster = aws_ecs_cluster.this.id

  task_definition = aws_ecs_task_definition.this.arn

  launch_type = "FARGATE"

  desired_count = var.desired_count

  enable_execute_command = true

  deployment_minimum_healthy_percent = 50

  deployment_maximum_percent = 200

  network_configuration {

    subnets = var.private_subnets

    security_groups = [
      var.ecs_security_group
    ]

    assign_public_ip = false

  }

  load_balancer {

    target_group_arn = var.target_group_arn

    container_name = var.container_name

    container_port = var.container_port

  }

  depends_on = [
    aws_ecs_task_definition.this
  ]

  tags = {

    Name = "${var.project_name}-${var.environment}-service"

  }

}
