provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnets" {
  type        = list(string)
  description = "List of subnet IDs"
}

variable "alb_name" {
  type        = string
  description = "ALB name"
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB security group ID"
}

variable "target_group_name" {
  type        = string
  description = "Target group name"
}

variable "target_group_port" {
  type        = number
  description = "Target group port"
}

variable "listener_rule_host_header" {
  type        = string
  description = "Listener rule host header"
}

variable "listener_rule_path_pattern" {
  type        = string
  description = "Listener rule path pattern"
}

resource "aws_alb" "this" {
  name            = var.alb_name
  subnets         = var.subnets
  security_groups = [var.alb_security_group_id]
}

resource "aws_alb_target_group" "this" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_alb_listener" "this" {
  load_balancer_arn = aws_alb.this.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.this.arn
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "this" {
  listener_arn = aws_alb_listener.this.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.this.arn
  }
  condition {
    field  = "host-header"
    values = [var.listener_rule_host_header]
  }
}

resource "aws_alb_listener_rule" "path_based" {
  listener_arn = aws_alb_listener.this.arn
  priority     = 2
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.this.arn
  }
  condition {
    field  = "path-pattern"
    values = [var.listener_rule_path_pattern]
  }
}