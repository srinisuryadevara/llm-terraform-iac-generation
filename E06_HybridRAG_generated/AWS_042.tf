# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Create a Route 53 Hosted Zone
resource "aws_route53_zone" "example" {
  name = var.domain_name
}

# Create an A Record in the Hosted Zone
resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "example"
  type    = "A"
  alias {
    name                   = aws_lb.example.dns_name
    zone_id                = aws_lb.example.zone_id
    evaluate_target_health = true
  }
}

# Create a CNAME Record in the Hosted Zone
resource "aws_route53_record" "cname_record" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "cname-example"
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.example.dns_name]
}

# Create an Application Load Balancer
resource "aws_lb" "example" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.example.id]
  subnets            = var.subnet_ids
}

# Create a Security Group for the Load Balancer
resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Security Group for the Load Balancer"
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

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "domain_name" {
  type        = string
  description = "Domain Name for the Hosted Zone"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the Load Balancer"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the Security Group"
}