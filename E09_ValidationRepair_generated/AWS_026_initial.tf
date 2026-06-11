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

variable "subnets" {
  type        = list(string)
  sensitive   = true
}

variable "instance_port" {
  type        = number
  default     = 80
}

variable "instance_protocol" {
  type        = string
  default     = "HTTP"
}

variable "listener_port" {
  type        = number
  default     = 80
}

variable "listener_protocol" {
  type        = string
  default     = "HTTP"
}

resource "aws_alb" "example" {
  name            = "example-alb"
  subnets         = var.subnets
  security_groups = [aws_security_group.example.id]
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Example security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.listener_port
    to_port     = var.listener_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb_target_group" "example" {
  name     = "example-tg"
  port     = var.instance_port
  protocol = var.instance_protocol
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

resource "aws_alb_listener_rule" "example" {
  listener_arn = aws_alb_listener.example.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.example.arn
  }

  condition {
    path_pattern {
      values = ["/example/*"]
    }
  }
}