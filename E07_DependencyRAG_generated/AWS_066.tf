# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "example-vpc"
  }
}

# Create subnets
resource "aws_subnet" "example1" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = var.subnet1_cidr_block
  availability_zone = var.availability_zone1
  tags = {
    Name = "example-subnet1"
  }
}

resource "aws_subnet" "example2" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = var.subnet2_cidr_block
  availability_zone = var.availability_zone2
  tags = {
    Name = "example-subnet2"
  }
}

# Create security group for the ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for the ALB"
  vpc_id      = aws_vpc.example.id

  ingress {
    description = "Allow HTTP traffic"
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

  tags = {
    Name = "alb-sg"
  }
}

# Create the ALB
resource "aws_lb" "example" {
  name               = "example-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.example1.id, aws_subnet.example2.id]
  security_groups    = [aws_security_group.alb_sg.id]
  enable_deletion_protection = false
  tags = {
    Environment = "example-alb"
  }
}

# Create target groups
resource "aws_lb_target_group" "example1" {
  name     = "example-tg1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.example.id

  health_check {
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/healthz/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 20
    unhealthy_threshold = 2
  }

  tags = {
    Name = "example-tg1"
  }
}

resource "aws_lb_target_group" "example2" {
  name     = "example-tg2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.example.id

  health_check {
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/healthz/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 20
    unhealthy_threshold = 2
  }

  tags = {
    Name = "example-tg2"
  }
}

# Create listener
resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.example1.arn
    type             = "forward"
  }
}

# Create listener rules
resource "aws_lb_listener_rule" "example1" {
  listener_arn = aws_lb_listener.example.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example1.arn
  }

  condition {
    path_pattern {
      values = ["/path1/*"]
    }
  }
}

resource "aws_lb_listener_rule" "example2" {
  listener_arn = aws_lb_listener.example.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example2.arn
  }

  condition {
    path_pattern {
      values = ["/path2/*"]
    }
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  description = "AWS profile"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block"
}

variable "subnet1_cidr_block" {
  type        = string
  description = "Subnet 1 CIDR block"
}

variable "subnet2_cidr_block" {
  type        = string
  description = "Subnet 2 CIDR block"
}

variable "availability_zone1" {
  type        = string
  description = "Availability zone 1"
}

variable "availability_zone2" {
  type        = string
  description = "Availability zone 2"
}