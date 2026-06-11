terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_lb" "application_load_balancer" {
  name               = var.alb_name
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [var.alb_security_group_id]
  enable_deletion_protection = false
  tags               = {
    Environment        = var.environment
  }
}

output "alb_arn" {
  value = aws_lb.application_load_balancer.arn
}

resource "aws_lb_target_group" "target_group" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = var.target_group_protocol
  target_type = "instance"
  vpc_id   = var.vpc_id
}

output "target_group_arn" {
  value = aws_lb_target_group.target_group.arn
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  condition {
    path_pattern {
      values = [var.listener_rule_path_pattern]
    }
  }
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_profile" {
  type        = string
  description = "AWS Profile"
}

variable "alb_name" {
  type        = string
  description = "ALB Name"
}

variable "public_subnets" {
  type        = list(string)
  description = "Public Subnets"
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB Security Group ID"
}

variable "environment" {
  type        = string
  description = "Environment"
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

variable "vpc_id" {
  type        = string
  description = "VPC ID"
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

variable "listener_rule_path_pattern" {
  type        = string
  description = "Listener Rule Path Pattern"
}