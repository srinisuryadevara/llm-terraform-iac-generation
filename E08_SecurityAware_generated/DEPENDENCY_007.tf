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

variable "target_group_name" {
  type        = string
  description = "Target Group Name"
}

variable "port" {
  type        = number
  description = "Listener Port"
}

variable "protocol" {
  type        = string
  description = "Listener Protocol"
}

variable "certificate_arn" {
  type        = string
  description = "Certificate ARN"
}

resource "aws_alb" "this" {
  name            = var.alb_name
  subnets         = var.subnets
  security_groups = [aws_security_group.alb.id]
  tags = {
    Name        = var.alb_name
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.alb_name}-sg"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = var.protocol
    cidr_blocks = [var.ssh_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.alb_name}-sg"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_alb_target_group" "this" {
  name     = var.target_group_name
  port     = var.port
  protocol = var.protocol
  vpc_id   = var.vpc_id
  tags = {
    Name        = var.target_group_name
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_alb_listener" "this" {
  load_balancer_arn = aws_alb.this.arn
  port              = var.port
  protocol          = var.protocol
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn
  default_action {
    target_group_arn = aws_alb_target_group.this.arn
    type             = "forward"
  }
  tags = {
    Name        = var.alb_name
    Project     = var.project
    Environment = var.environment
  }
}