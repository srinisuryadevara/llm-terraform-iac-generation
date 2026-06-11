terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = ">= 2.7.0"
  }
}

variable "lb_name" {
  type        = string
  description = "The name of the load balancer"
}

variable "lb_type" {
  type        = string
  description = "The type of the load balancer"
}

variable "lb_port" {
  type        = number
  description = "The port of the load balancer"
}

variable "lb_protocol" {
  type        = string
  description = "The protocol of the load balancer"
}

variable "security_group_id" {
  type        = string
  description = "The ID of the security group"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "The IDs of the public subnets"
}

variable "target_group_port" {
  type        = number
  description = "The port of the target group"
}

variable "target_group_protocol" {
  type        = string
  description = "The protocol of the target group"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

resource "aws_lb" "main" {
  name               = var.lb_name
  internal           = false
  load_balancer_type = var.lb_type
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "main" {
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.lb_port
  protocol          = var.lb_protocol

  default_action {
    target_group_arn = aws_lb_target_group.main.arn
    type             = "forward"
  }
}