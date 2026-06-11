variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet1" {
  type        = string
  description = "Public Subnet 1 ID"
}

variable "public_subnet2" {
  type        = string
  description = "Public Subnet 2 ID"
}

variable "external_alb_sg" {
  type        = string
  description = "External ALB Security Group ID"
}

variable "port" {
  type        = number
  description = "Port number"
}

variable "target_type" {
  type        = string
  description = "Target type"
}

variable "health_check_path" {
  type        = string
  description = "Health check path"
}

variable "health_check_port" {
  type        = number
  description = "Health check port"
}

variable "health_check_protocol" {
  type        = string
  description = "Health check protocol"
}

variable "health_check_timeout" {
  type        = number
  description = "Health check timeout"
}

variable "health_check_interval" {
  type        = number
  description = "Health check interval"
}

variable "health_check_healthy_threshold" {
  type        = number
  description = "Health check healthy threshold"
}

variable "health_check_unhealthy_threshold" {
  type        = number
  description = "Health check unhealthy threshold"
}

variable "health_check_matcher" {
  type        = string
  description = "Health check matcher"
}

provider "aws" {
  region  = var.aws_region
}

resource "aws_lb" "alb" {
  name               = "Application-Load-Balancer"
  load_balancer_type = "application"
  subnets            = [var.public_subnet1, var.public_subnet2]
  security_groups    = [var.external_alb_sg]
  enable_deletion_protection = false
}

output "alb_arn" {
  value = aws_lb.alb.arn
}

resource "aws_lb_target_group" "tg" {
  name     = "Target-Group"
  port     = var.port
  protocol = "HTTP"
  target_type = var.target_type
  vpc_id   = var.vpc_id

  health_check {
    path                = var.health_check_path
    port                = var.health_check_port
    protocol            = var.health_check_protocol
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher             = var.health_check_matcher
  }
}

output "tg_arn" {
  value = aws_lb_target_group.tg.arn
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_listener_rule" "rule" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}