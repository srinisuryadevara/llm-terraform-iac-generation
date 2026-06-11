provider "aws" {
  region = var.aws_region
}

resource "aws_alb" "example" {
  name            = var.alb_name
  subnets         = var.subnet_ids
  security_groups = var.security_group_ids

  tags = {
    Name        = var.alb_name
    Environment = "example"
  }
}

resource "aws_alb_target_group" "example" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id

  tags = {
    Name        = var.target_group_name
    Environment = "example"
  }
}

resource "aws_alb_listener" "example" {
  load_balancer_arn = aws_alb.example.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    target_group_arn = aws_alb_target_group.example.arn
    type             = "forward"
  }

  tags = {
    Name        = "example-listener"
    Environment = "example"
  }
}

resource "aws_alb_listener_rule" "example" {
  listener_arn = aws_alb_listener.example.arn
  priority     = var.rule_priority

  action {
    target_group_arn = aws_alb_target_group.example.arn
    type             = "forward"
  }

  condition {
    path_pattern {
      values = [var.rule_path_pattern]
    }
  }

  tags = {
    Name        = "example-rule"
    Environment = "example"
  }
}

variable "aws_region" {
  type = string
}

variable "alb_name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "target_group_name" {
  type = string
}

variable "target_group_port" {
  type = number
}

variable "target_group_protocol" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "listener_port" {
  type = number
}

variable "listener_protocol" {
  type = string
}

variable "rule_priority" {
  type = number
}

variable "rule_path_pattern" {
  type = string
}

output "alb_id" {
  value = aws_alb.example.id
}

output "alb_arn" {
  value = aws_alb.example.arn
}

output "alb_dns_name" {
  value = aws_alb.example.dns_name
}

output "target_group_id" {
  value = aws_alb_target_group.example.id
}

output "target_group_arn" {
  value = aws_alb_target_group.example.arn
}

output "listener_id" {
  value = aws_alb_listener.example.id
}

output "listener_arn" {
  value = aws_alb_listener.example.arn
}

output "listener_rule_id" {
  value = aws_alb_listener_rule.example.id
}

output "listener_rule_arn" {
  value = aws_alb_listener_rule.example.arn
}