provider "aws" {
  region = var.aws_region
}

resource "aws_alb" "example" {
  name            = var.alb_name
  subnets         = var.subnet_ids
  security_groups = var.security_group_ids
}

resource "aws_alb_target_group" "example" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id
}

resource "aws_alb_listener" "example" {
  load_balancer_arn = aws_alb.example.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    target_group_arn = aws_alb_target_group.example.arn
    type             = "forward"
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
    field  = "path-pattern"
    values = [var.rule_path_pattern]
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
  description = "Subnet IDs"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group IDs"
}

variable "target_group_name" {
  type        = string
  description = "Target group name"
}

variable "target_group_port" {
  type        = number
  description = "Target group port"
}

variable "target_group_protocol" {
  type        = string
  description = "Target group protocol"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "listener_port" {
  type        = number
  description = "Listener port"
}

variable "listener_protocol" {
  type        = string
  description = "Listener protocol"
}

variable "rule_priority" {
  type        = number
  description = "Rule priority"
}

variable "rule_path_pattern" {
  type        = string
  description = "Rule path pattern"
}