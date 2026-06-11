variable "alb_name" {
  type        = string
  description = "The name of the Application Load Balancer"
}

variable "alb_type" {
  type        = string
  description = "The type of the Application Load Balancer"
  default     = "application"
}

variable "internal" {
  type        = bool
  description = "Whether the load balancer is internal or not"
  default     = false
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "subnets" {
  type        = list(string)
  description = "The IDs of the subnets"
}

variable "security_group_id" {
  type        = string
  description = "The ID of the security group"
}

variable "lb_port" {
  type        = number
  description = "The port of the load balancer"
  default     = 80
}

variable "lb_protocol" {
  type        = string
  description = "The protocol of the load balancer"
  default     = "HTTP"
}

variable "target_group_port" {
  type        = number
  description = "The port of the target group"
  default     = 80
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
  default     = 1
}

variable "listener_rule_path_pattern" {
  type        = string
  description = "The path pattern of the listener rule"
  default     = "*"
}

variable "health_check_healthy_threshold" {
  type        = number
  description = "The healthy threshold of the health check"
  default     = 2
}

variable "health_check_interval" {
  type        = number
  description = "The interval of the health check"
  default     = 30
}

variable "health_check_matcher" {
  type        = string
  description = "The matcher of the health check"
  default     = "200"
}

variable "health_check_path" {
  type        = string
  description = "The path of the health check"
  default     = "/healthz/"
}

variable "health_check_timeout" {
  type        = number
  description = "The timeout of the health check"
  default     = 20
}

variable "health_check_unhealthy_threshold" {
  type        = number
  description = "The unhealthy threshold of the health check"
  default     = 2
}

variable "tags" {
  type        = map(string)
  description = "The tags of the resources"
  default     = {}
}

resource "aws_lb" "main" {
  name               = var.alb_name
  internal           = var.internal
  load_balancer_type = var.alb_type
  security_groups    = [var.security_group_id]
  subnets            = var.subnets
  enable_deletion_protection = false
  tags               = var.tags
}

resource "aws_lb_target_group" "main" {
  name     = "IP-lb-instancetype-tg"
  port     = var.target_group_port
  protocol = var.target_group_protocol
  target_type = "instance"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    matcher             = var.health_check_matcher
    path                = var.health_check_path
    port                = var.target_group_port
    protocol            = var.target_group_protocol
    timeout             = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = var.tags
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.lb_port
  protocol          = var.lb_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
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

output "alb_arn" {
  value = aws_lb.main.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.main.arn
}

output "listener_arn" {
  value = aws_lb_listener.main.arn
}