provider "aws" {
  region = var.region
}

resource "aws_lb" "main" {
  name               = var.lb_name
  internal           = var.internal
  load_balancer_type = var.lb_type
  security_groups    = [aws_security_group.main.id]
  subnets            = var.public_subnet_ids
}

resource "aws_security_group" "main" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = var.vpc_id
}

resource "aws_lb_target_group" "main" {
  port     = var.lb_port
  protocol = var.lb_protocol
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

variable "region" {
  type        = string
  description = "AWS region"
}

variable "lb_name" {
  type        = string
  description = "Load balancer name"
}

variable "internal" {
  type        = bool
  description = "Whether the load balancer is internal"
}

variable "lb_type" {
  type        = string
  description = "Load balancer type"
}

variable "security_group_name" {
  type        = string
  description = "Security group name"
}

variable "security_group_description" {
  type        = string
  description = "Security group description"
}

variable "lb_port" {
  type        = number
  description = "Load balancer port"
}

variable "lb_protocol" {
  type        = string
  description = "Load balancer protocol"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}