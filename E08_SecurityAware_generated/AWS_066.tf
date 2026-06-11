provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project Name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnets" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH Allowed CIDR"
}

variable "alb_name" {
  type        = string
  description = "ALB Name"
}

variable "alb_port" {
  type        = number
  description = "ALB Port"
}

variable "alb_protocol" {
  type        = string
  description = "ALB Protocol"
}

variable "target_group_name" {
  type        = string
  description = "Target Group Name"
}

variable "target_group_port" {
  type        = number
  description = "Target Group Port"
}

variable "target_group_protocol" {
  type        = string
  description = "Target Group Protocol"
}

variable "listener_rule_priority" {
  type        = number
  description = "Listener Rule Priority"
}

variable "listener_rule_host_header" {
  type        = string
  description = "Listener Rule Host Header"
}

variable "listener_rule_path_pattern" {
  type        = string
  description = "Listener Rule Path Pattern"
}

resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description = "ALB Ingress"
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
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnets

  tags = {
    Name        = var.alb_name
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_lb_target_group" "alb" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/"
    port                = var.target_group_port
  }

  tags = {
    Name        = var.target_group_name
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_lb_listener" "alb" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.alb_port
  protocol          = var.alb_protocol

  default_action {
    target_group_arn = aws_lb_target_group.alb.arn
    type             = "forward"
  }

  tags = {
    Name        = "${var.alb_name}-listener"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_lb_listener_rule" "alb" {
  listener_arn = aws_lb_listener.alb.arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
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