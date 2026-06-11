provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "domain_name" {
  type        = string
  description = "Domain name for the hosted zone"
}

variable "environment" {
  type        = string
  description = "Environment tag"
}

resource "aws_route53_zone" "primary" {
  name = var.domain_name

  tags = {
    Environment = var.environment
  }
}

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.primary.id
  name    = "example"
  type    = "A"
  ttl     = 300
  records = ["10.0.0.1"]

  tags = {
    Environment = var.environment
  }
}

resource "aws_route53_record" "cname_record" {
  zone_id = aws_route53_zone.primary.id
  name    = "blog"
  type    = "CNAME"
  ttl     = 300
  records = ["example.com"]

  tags = {
    Environment = var.environment
  }
}