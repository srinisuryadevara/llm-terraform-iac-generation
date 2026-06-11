provider "aws" {
  region = var.aws_region
}

resource "aws_alb" "example" {
  name            = var.alb_name
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.example.id]
  internal        = true

  tags = {
    Name        = var.alb_name
    Environment = "example"
  }
}

resource "aws_security_group" "example" {
  name        = var.security_group_name
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name        = var.security_group_name
    Environment = "example"
  }
}

resource "aws_alb_target_group" "example1" {
  name     = var.target_group_name1
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = {
    Name        = var.target_group_name1
    Environment = "example"
  }
}

resource "aws_alb_target_group" "example2" {
  name     = var.target_group_name2
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = {
    Name        = var.target_group_name2
    Environment = "example"
  }
}

resource "aws_alb_listener" "example" {
  load_balancer_arn = aws_alb.example.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.example1.arn
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "example1" {
  listener_arn = aws_alb_listener.example.arn
  priority     = 1

  condition {
    field  = "path-pattern"
    values = ["/path1/*"]
  }

  action {
    target_group_arn = aws_alb_target_group.example1.arn
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "example2" {
  listener_arn = aws_alb_listener.example.arn
  priority     = 2

  condition {
    field  = "path-pattern"
    values = ["/path2/*"]
  }

  action {
    target_group_arn = aws_alb_target_group.example2.arn
    type             = "forward"
  }
}

variable "aws_region" {
  type        = string
  default     = "us-west-2"
}

variable "alb_name" {
  type        = string
  default     = "example-alb"
}

variable "subnet_ids" {
  type        = list(string)
  default     = ["subnet-12345678", "subnet-23456789"]
}

variable "security_group_name" {
  type        = string
  default     = "example-sg"
}

variable "vpc_id" {
  type        = string
  default     = "vpc-12345678"
}

variable "target_group_name1" {
  type        = string
  default     = "example-tg1"
}

variable "target_group_name2" {
  type        = string
  default     = "example-tg2"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "certificate_arn" {
  type        = string
  default     = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"
}

output "alb_arn" {
  value       = aws_alb.example.arn
  description = "The ARN of the ALB"
}

output "alb_dns_name" {
  value       = aws_alb.example.dns_name
  description = "The DNS name of the ALB"
}

output "target_group_arn1" {
  value       = aws_alb_target_group.example1.arn
  description = "The ARN of the first target group"
}

output "target_group_arn2" {
  value       = aws_alb_target_group.example2.arn
  description = "The ARN of the second target group"
}