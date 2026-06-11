provider "aws" {
  region = var.aws_region
}

resource "aws_alb" "example" {
  name            = var.alb_name
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.example.id]
}

resource "aws_security_group" "example" {
  name        = var.security_group_name
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb_target_group" "example" {
  name     = var.target_group_name
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
      values = ["/"]
    }
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "alb_name" {
  type        = string
  description = "ALB name"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs"
}

variable "security_group_name" {
  type        = string
  description = "Security group name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "target_group_name" {
  type        = string
  description = "Target group name"
}