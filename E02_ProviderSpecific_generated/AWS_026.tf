provider "aws" {
  region = var.region
}

resource "aws_alb" "example" {
  name            = "example-alb"
  subnets         = [var.subnet1, var.subnet2]
  security_groups = [var.security_group]
}

resource "aws_alb_target_group" "example" {
  name     = "example-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_alb_listener" "example" {
  load_balancer_arn = aws_alb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.example.arn
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "example" {
  listener_arn = aws_alb_listener.example.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.example.arn
  }

  condition {
    path_pattern {
      values = ["/example/*"]
    }
  }
}