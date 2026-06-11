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
  description = "Environment Name"
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
  description = "SSH CIDR"
}

variable "alb_name" {
  type        = string
  description = "ALB Name"
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB Security Group ID"
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

variable "listener_rule_path_pattern" {
  type        = string
  description = "Listener Rule Path Pattern"
}

resource "aws_alb" "this" {
  name            = var.alb_name
  subnets         = var.subnets
  security_groups = [var.alb_security_group_id]
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_alb_target_group" "this" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = var.listener_protocol
  vpc_id   = var.vpc_id
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_alb_listener" "this" {
  load_balancer_arn = aws_alb.this.arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn
  default_action {
    target_group_arn = aws_alb_target_group.this.arn
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "this" {
  listener_arn = aws_alb_listener.this.arn
  priority     = var.listener_rule_priority
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

resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = var.listener_port
    to_port     = var.listener_port
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

variable "certificate_arn" {
  type        = string
  description = "Certificate ARN"
}