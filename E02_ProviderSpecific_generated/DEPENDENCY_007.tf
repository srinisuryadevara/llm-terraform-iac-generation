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

variable "target_group_name" {
  type        = string
  sensitive   = true
}

variable "port" {
  type        = number
  sensitive   = true
}

variable "protocol" {
  type        = string
  sensitive   = true
}

resource "aws_alb" "this" {
  name            = var.alb_name
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_security_group" "alb" {
  name        = "${var.alb_name}-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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
  port     = var.port
  protocol = var.protocol
  vpc_id   = var.vpc_id
}

resource "aws_alb_listener" "this" {
  load_balancer_arn = aws_alb.this.arn
  port              = var.port
  protocol          = var.protocol

  default_action {
    target_group_arn = aws_alb_target_group.this.arn
    type             = "forward"
  }
}