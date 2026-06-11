provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnets" {
  type        = list(string)
  description = "List of subnet IDs"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH allowed CIDR"
}

variable "alb_name" {
  type        = string
  description = "ALB name"
}

variable "alb_port" {
  type        = number
  description = "ALB port"
}

variable "alb_protocol" {
  type        = string
  description = "ALB protocol"
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

variable "listener_rule_priority" {
  type        = number
  description = "Listener rule priority"
}

variable "listener_rule_host_header" {
  type        = string
  description = "Listener rule host header"
}

variable "listener_rule_path_pattern" {
  type        = string
  description = "Listener rule path pattern"
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "ALB ingress"
    from_port   = var.alb_port
    to_port     = var.alb_port
    protocol    = var.alb_protocol
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-alb-sg"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_lb" "alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnets

  enable_deletion_protection = false

  tags = {
    Name        = var.alb_name
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_lb_target_group" "target_group" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/healthcheck"
    port                = var.target_group_port
  }

  tags = {
    Name        = var.target_group_name
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.alb_port
  protocol          = var.alb_protocol

  default_action {
    target_group_arn = aws_lb_target_group.target_group.arn
    type             = "forward"
  }

  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  tags = {
    Name        = "${var.alb_name}-listener"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  condition {
    host_header {
      values = [var.listener_rule_host_header]
    }
  }

  condition {
    path_pattern {
      values = [var.listener_rule_path_pattern]
    }
  }

  tags = {
    Name        = "${var.alb_name}-listener-rule"
    Environment = var.environment
    Project     = var.project
  }
}

variable "certificate_arn" {
  type        = string
  description = "Certificate ARN"
}