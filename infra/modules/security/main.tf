###########################################
# ALB Security Group
###########################################

resource "aws_security_group" "alb" {

  name        = "${var.project_name}-${var.environment}-alb-sg"

  description = "Allow HTTP from Internet"

  vpc_id = var.vpc_id

  ingress {

    description = "HTTP"

    from_port = 80

    to_port = 80

    protocol = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]

  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]

  }

  tags = {

    Name = "${var.project_name}-alb-sg"

  }

}

###########################################
# ECS Security Group
###########################################

resource "aws_security_group" "ecs" {

  name = "${var.project_name}-${var.environment}-ecs-sg"

  description = "Allow traffic only from ALB"

  vpc_id = var.vpc_id

  ingress {

    description = "ALB to ECS"

    from_port = 80

    to_port = 80

    protocol = "tcp"

    security_groups = [
      aws_security_group.alb.id
    ]

  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]

  }

  tags = {

    Name = "${var.project_name}-ecs-sg"

  }

}

###########################################
# RDS Security Group
###########################################

resource "aws_security_group" "rds" {

  name = "${var.project_name}-${var.environment}-rds-sg"

  description = "Allow PostgreSQL only from ECS"

  vpc_id = var.vpc_id

  ingress {

    description = "PostgreSQL"

    from_port = 5432

    to_port = 5432

    protocol = "tcp"

    security_groups = [
      aws_security_group.ecs.id
    ]

  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]

  }

  tags = {

    Name = "${var.project_name}-rds-sg"

  }

}
