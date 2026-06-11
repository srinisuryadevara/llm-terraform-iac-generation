provider "aws" {
  region = var.aws_region
}

resource "aws_alb" "example" {
  name            = var.alb_name
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.example.id]
}

resource "aws_security_group" "example" {
  name        = var.security_group_name
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_alb_target_group" "example1" {
  name     = var.target_group_name1
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_alb_target_group" "example2" {
  name     = var.target_group_name2
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_alb_listener" "example" {
  load_balancer_arn = aws_alb.example.arn
  port              = "80"
  protocol          = "HTTP"

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