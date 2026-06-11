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
  default     = 443
}

variable "listener_protocol" {
  type        = string
  default     = "HTTPS"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

resource "aws_alb" "example" {
  name            = "example-alb"
  subnets         = var.subnets
  security_groups = [aws_security_group.example.id]
  internal        = true

  tags = {
    Name        = "example-alb"
    Environment = "example"
  }
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Example security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.listener_port
    to_port     = var.listener_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "example-sg"
    Environment = "example"
  }
}

resource "aws_alb_target_group" "example" {
  name     = "example-tg"
  port     = var.instance_port
  protocol = var.instance_protocol
  vpc_id   = var.vpc_id

  tags = {
    Name        = "example-tg"
    Environment = "example"
  }
}

resource "aws_alb_listener" "example" {
  load_balancer_arn = aws_alb.example.arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  certificate_arn   = aws_acm_certificate.example.arn

  default_action {
    target_group_arn = aws_alb_target_group.example.arn
    type             = "forward"
  }

  tags = {
    Name        = "example-listener"
    Environment = "example"
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

  tags = {
    Name        = "example-listener-rule"
    Environment = "example"
  }
}

resource "aws_acm_certificate" "example" {
  domain_name       = "example.com"
  validation_method = "DNS"
}

output "alb_id" {
  value = aws_alb.example.id
}

output "alb_arn" {
  value = aws_alb.example.arn
}

output "alb_dns_name" {
  value = aws_alb.example.dns_name
}

output "target_group_id" {
  value = aws_alb_target_group.example.id
}

output "target_group_arn" {
  value = aws_alb_target_group.example.arn
}

output "listener_arn" {
  value = aws_alb_listener.example.arn
}