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
  description = "Environment name"
}

variable "project" {
  type        = string
  description = "Project name"
}

resource "aws_route53_zone" "this" {
  name = var.domain_name

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.this.id
  name    = "example"
  type    = "A"
  ttl     = 300
  records = ["192.0.2.1"]

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_route53_record" "cname_record" {
  zone_id = aws_route53_zone.this.id
  name    = "www"
  type    = "CNAME"
  ttl     = 300
  records = ["example.${var.domain_name}"]

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}