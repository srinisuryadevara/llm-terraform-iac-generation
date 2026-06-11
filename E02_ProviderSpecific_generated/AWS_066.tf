provider "aws" {
  region = var.region
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "instance_port" {
  type = number
}

variable "instance_protocol" {
  type = string
}

variable "listener_port" {
  type = number
}

variable "listener_protocol" {
  type = string
}

variable "target_group_name" {
  type = string
}

variable "listener_rule_host_header" {
  type = string
}

resource "aws_alb" "example" {
  name            = "example-alb"
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.example.id]
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Example security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.listener_port
    to_port     = var.listener_port
    protocol    = var.listener_protocol
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb_target_group" "example" {
  name     = var.target_group_name
  port     = var.instance_port
  protocol = var.instance_protocol
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
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.example.arn
  }

  condition {
    field  = "host-header"
    values = [var.listener_rule_host_header]
  }
}