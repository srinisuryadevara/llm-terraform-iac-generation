variable "alb_name" {
  type        = string
  description = "The name of the Application Load Balancer"
}

variable "internal" {
  type        = bool
  description = "Whether the load balancer is internal or not"
}

variable "lb_type" {
  type        = string
  description = "The type of load balancer"
}

variable "security_group_id" {
  type        = string
  description = "The ID of the security group"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "The IDs of the public subnets"
}

variable "lb_port" {
  type        = number
  description = "The port of the load balancer"
}

variable "lb_protocol" {
  type        = string
  description = "The protocol of the load balancer"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "instance_ids" {
  type        = list(string)
  description = "The IDs of the instances"
}

variable "target_group_name" {
  type        = string
  description = "The name of the target group"
}

variable "target_group_port" {
  type        = number
  description = "The port of the target group"
}

variable "target_group_protocol" {
  type        = string
  description = "The protocol of the target group"
}

variable "health_check_path" {
  type        = string
  description = "The path of the health check"
}

variable "health_check_interval" {
  type        = number
  description = "The interval of the health check"
}

variable "health_check_timeout" {
  type        = number
  description = "The timeout of the health check"
}

variable "health_check_healthy_threshold" {
  type        = number
  description = "The healthy threshold of the health check"
}

variable "health_check_unhealthy_threshold" {
  type        = number
  description = "The unhealthy threshold of the health check"
}

resource "aws_lb" "alb" {
  name               = var.alb_name
  internal           = var.internal
  load_balancer_type = var.lb_type
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "tg" {
  name     = var.target_group_name
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id

  health_check {
    path                = var.health_check_path
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.lb_port
  protocol          = var.lb_protocol

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "attachment" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = var.instance_ids[count.index]
  port             = var.target_group_port
}

output "alb_arn" {
  value = aws_lb.alb.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.tg.arn
}