provider "aws" {
  region = var.aws_region
}

resource "aws_alb" "example" {
  name            = var.alb_name
  subnets         = var.alb_subnets
  security_groups = var.alb_security_groups
}

resource "aws_alb_target_group" "example" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = var.target_group_protocol
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

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "alb_name" {
  type        = string
  description = "ALB name"
}

variable "alb_subnets" {
  type        = list(string)
  description = "ALB subnets"
}

variable "alb_security_groups" {
  type        = list(string)
  description = "ALB security groups"
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

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "listener_port" {
  type        = number
  description = "Listener port"
}

variable "listener_protocol" {
  type        = string
  description = "Listener protocol"
}