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

output "alb_arn" {
  value       = aws_alb.example.arn
  description = "The ARN of the ALB"
}

output "alb_dns_name" {
  value       = aws_alb.example.dns_name
  description = "The DNS name of the ALB"
}

output "target_group_arn" {
  value       = aws_alb_target_group.example.arn
  description = "The ARN of the target group"
}

output "listener_arn" {
  value       = aws_alb_listener.example.arn
  description = "The ARN of the listener"
}