variable "alb_name" {
  type        = string
  description = "The name of the Application Load Balancer"
}

variable "alb_type" {
  type        = string
  description = "The type of the Application Load Balancer"
  default     = "application"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "subnets" {
  type        = list(string)
  description = "The IDs of the subnets"
}

variable "security_groups" {
  type        = list(string)
  description = "The IDs of the security groups"
}

variable "listener_port" {
  type        = number
  description = "The port of the listener"
}

variable "listener_protocol" {
  type        = string
  description = "The protocol of the listener"
  default     = "HTTP"
}

variable "target_group_port" {
  type        = number
  description = "The port of the target group"
}

variable "target_group_protocol" {
  type        = string
  description = "The protocol of the target group"
  default     = "HTTP"
}

variable "instance_ids" {
  type        = list(string)
  description = "The IDs of the instances"
}

variable "listener_rule_priority" {
  type        = number
  description = "The priority of the listener rule"
}

variable "listener_rule_path_pattern" {
  type        = string
  description = "The path pattern of the listener rule"
}

resource "aws_lb" "main" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = var.alb_type
  security_groups    = var.security_groups
  subnets            = var.subnets
}

resource "aws_lb_target_group" "main" {
  name     = "${var.alb_name}-target-group"
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    target_group_arn = aws_lb_target_group.main.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "main" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = var.instance_ids[count.index]
  port             = var.target_group_port
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.main.arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    path_pattern {
      values = [var.listener_rule_path_pattern]
    }
  }
}