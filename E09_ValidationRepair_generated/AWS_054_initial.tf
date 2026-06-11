provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  type        = list(string)
  sensitive   = true
}

variable "alb_name" {
  type        = string
  sensitive   = true
}

variable "alb_security_group_id" {
  type        = string
  sensitive   = true
}

variable "target_group_name" {
  type        = string
  sensitive   = true
}

variable "target_group_port" {
  type        = number
  sensitive   = true
}

variable "listener_rule_host_header" {
  type        = string
  sensitive   = true
}

variable "listener_rule_path_pattern" {
  type        = string
  sensitive   = true
}

resource "aws_alb" "this" {
  name            = var.alb_name
  subnets         = var.subnet_ids
  security_groups = [var.alb_security_group_id]
  internal        = false
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
    target_group_arn = aws_alb_target_group.this.arn
    type             = "forward"
  }

  condition {
    field  = "host-header"
    values = [var.listener_rule_host_header]
  }

  condition {
    field  = "path-pattern"
    values = [var.listener_rule_path_pattern]
  }
}