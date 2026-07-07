#############################################
# Application Load Balancer
#############################################

resource "aws_lb" "this" {

  name               = "${var.project_name}-${var.environment}-alb"

  internal           = false

  load_balancer_type = "application"

  security_groups = [
    var.alb_security_group
  ]

  subnets = var.public_subnets

  enable_deletion_protection = false

  idle_timeout = 60

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }

}

#############################################
# Target Group
#############################################

resource "aws_lb_target_group" "this" {

  name = "${var.project_name}-${var.environment}-tg"

  port = var.target_port

  protocol = "HTTP"

  target_type = "ip"

  vpc_id = var.vpc_id

  health_check {

    enabled = true

    interval = 30

    path = var.health_check_path

    protocol = "HTTP"

    timeout = 5

    healthy_threshold = 2

    unhealthy_threshold = 2

    matcher = "200"

  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tg"
  }

}

#############################################
# HTTP Listener
#############################################

resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.this.arn

  port = 80

  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.this.arn

  }

}
