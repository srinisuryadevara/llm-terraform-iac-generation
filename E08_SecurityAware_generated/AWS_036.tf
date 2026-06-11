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

variable "subnets" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH allowed CIDR"
}

variable "alb_name" {
  type        = string
  description = "ALB Name"
}

variable "alb_tags" {
  type        = map(string)
  description = "ALB Tags"
}

variable "target_group_name" {
  type        = string
  description = "Target Group Name"
}

variable "target_group_port" {
  type        = number
  description = "Target Group Port"
}

variable "listener_port" {
  type        = number
  description = "Listener Port"
}

variable "listener_protocol" {
  type        = string
  description = "Listener Protocol"
}

variable "listener_rule_priority" {
  type        = number
  description = "Listener Rule Priority"
}

variable "listener_rule_host_header" {
  type        = string
  description = "Listener Rule Host Header"
}

resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.alb_tags
}

resource "aws_lb" "alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnets

  tags = var.alb_tags
}

resource "aws_lb_target_group" "alb" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/"
    port                = "traffic-port"
  }

  tags = var.alb_tags
}

resource "aws_lb_listener" "alb" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    target_group_arn = aws_lb_target_group.alb.arn
    type             = "forward"
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
}