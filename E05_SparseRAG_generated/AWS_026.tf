variable "alb_name" {
  type        = string
  description = "The name of the Application Load Balancer"
}

variable "alb_internal" {
  type        = bool
  description = "Whether the Application Load Balancer is internal or not"
}

variable "alb_type" {
  type        = string
  description = "The type of the Application Load Balancer"
}

variable "security_group_id" {
  type        = string
  description = "The ID of the security group for the Application Load Balancer"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "The IDs of the public subnets for the Application Load Balancer"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC for the Application Load Balancer"
}

variable "instance_ids" {
  type        = list(string)
  description = "The IDs of the instances for the target group"
}

variable "alb_port" {
  type        = number
  description = "The port number for the Application Load Balancer"
}

variable "alb_protocol" {
  type        = string
  description = "The protocol for the Application Load Balancer"
}

variable "target_group_port" {
  type        = number
  description = "The port number for the target group"
}

variable "target_group_protocol" {
  type        = string
  description = "The protocol for the target group"
}

variable "listener_rule_priority" {
  type        = number
  description = "The priority for the listener rule"
}

variable "listener_rule_host_header" {
  type        = string
  description = "The host header for the listener rule"
}

variable "listener_rule_path_pattern" {
  type        = string
  description = "The path pattern for the listener rule"
}

resource "aws_lb" "main" {
  name               = var.alb_name
  internal           = var.alb_internal
  load_balancer_type = var.alb_type
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "main" {
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group_attachment" "main" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.main.arn
  port             = var.target_group_port
  target_id        = var.instance_ids[count.index]
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.alb_port
  protocol          = var.alb_protocol

  default_action {
    target_group_arn = aws_lb_target_group.main.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.main.arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
    order            = 1
  }

  condition {
    host_header {
      values = [var.listener_rule_host_header]
    }
  }

  condition {
    path_pattern {
      values = [var.listener_rule_path_pattern]
    }
  }
}