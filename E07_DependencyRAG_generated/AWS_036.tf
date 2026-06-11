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
  cidr_block = var.vpc_cidr

  tags = {
    Name = "example-vpc"
  }
}

# Create subnets
resource "aws_subnet" "example" {
  count = 2

  vpc_id            = aws_vpc.example.id
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "example-subnet-${count.index}"
  }
}

# Create security group for the ALB
resource "aws_security_group" "alb" {
  name        = "alb-security-group"
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
    Name = "alb-security-group"
  }
}

# Create the ALB
resource "aws_lb" "example" {
  name               = "example-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.example.*.id
  security_groups    = [aws_security_group.alb.id]

  tags = {
    Name = "example-alb"
  }
}

# Create target groups
resource "aws_lb_target_group" "example" {
  name     = "example-target-group"
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
    Name = "example-target-group"
  }
}

# Create listener
resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.example.arn
    type             = "forward"
  }
}

# Create listener rule
resource "aws_lb_listener_rule" "example" {
  listener_arn = aws_lb_listener.example.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }

  condition {
    path_pattern {
      values = ["/example/*"]
    }
  }
}

# Output the ALB DNS name
output "alb_dns_name" {
  value = aws_lb.example.dns_name
}