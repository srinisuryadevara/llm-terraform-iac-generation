provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of Subnet IDs"
}

variable "instance_port" {
  type        = number
  description = "Instance Port"
}

variable "instance_protocol" {
  type        = string
  description = "Instance Protocol"
}

variable "listener_port" {
  type        = number
  description = "Listener Port"
}

variable "listener_protocol" {
  type        = string
  description = "Listener Protocol"
}

variable "target_group_name" {
  type        = string
  description = "Target Group Name"
}

variable "listener_rule_path_pattern" {
  type        = string
  description = "Listener Rule Path Pattern"
}

variable "listener_rule_host_header" {
  type        = string
  description = "Listener Rule Host Header"
}

resource "aws_alb" "this" {
  name            = "alb-${var.target_group_name}"
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_security_group" "alb" {
  name        = "alb-sg-${var.target_group_name}"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.listener_port
    to_port     = var.listener_port
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

resource "aws_alb_target_group" "this" {
  name     = var.target_group_name
  port     = var.instance_port
  protocol = var.instance_protocol
  vpc_id   = var.vpc_id
}

resource "aws_alb_listener" "this" {
  load_balancer_arn = aws_alb.this.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

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
    path_pattern {
      values = [var.listener_rule_path_pattern]
    }
  }

  condition {
    host_header {
      values = [var.listener_rule_host_header]
    }
  }
}