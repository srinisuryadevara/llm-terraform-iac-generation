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

variable "alb_security_group_id" {
  type        = string
  sensitive   = true
}

variable "target_group_name" {
  type        = string
  sensitive   = true
}

variable "target_group_port" {
  type        = number
  sensitive   = true
}

variable "listener_rule_host_header" {
  type        = string
  sensitive   = true
}

variable "listener_rule_path_pattern" {
  type        = string
  sensitive   = true
}

resource "aws_alb" "this" {
  name            = var.alb_name
  subnets         = var.subnet_ids
  security_groups = [var.alb_security_group_id]
  internal        = false

  tags = {
    Name        = var.alb_name
    Environment = "production"
  }
}

resource "aws_alb_target_group" "this" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = {
    Name        = var.target_group_name
    Environment = "production"
  }
}

resource "aws_alb_listener" "this" {
  load_balancer_arn = aws_alb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.this.arn
    type             = "forward"
  }

  tags = {
    Name        = "${var.alb_name}-listener"
    Environment = "production"
  }
}

resource "aws_alb_listener_rule" "this" {
  listener_arn = aws_alb_listener.this.arn
  priority     = 1

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

  tags = {
    Name        = "${var.alb_name}-listener-rule"
    Environment = "production"
  }
}

output "alb_id" {
  value       = aws_alb.this.id
  description = "The ID of the Application Load Balancer"
}

output "alb_arn" {
  value       = aws_alb.this.arn
  description = "The ARN of the Application Load Balancer"
}

output "alb_dns_name" {
  value       = aws_alb.this.dns_name
  description = "The DNS name of the Application Load Balancer"
}

output "target_group_id" {
  value       = aws_alb_target_group.this.id
  description = "The ID of the Target Group"
}

output "target_group_arn" {
  value       = aws_alb_target_group.this.arn
  description = "The ARN of the Target Group"
}

output "listener_arn" {
  value       = aws_alb_listener.this.arn
  description = "The ARN of the Listener"
}