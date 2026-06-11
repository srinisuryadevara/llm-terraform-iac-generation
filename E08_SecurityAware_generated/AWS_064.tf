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
  records = ["192.0.2.1"]

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

resource "aws_kms_key" "route53" {
  description             = "KMS key for Route 53"
  deletion_window_in_days = 10

  tags = {
    Environment = var.environment
  }
}

resource "aws_kms_alias" "route53" {
  name          = "alias/route53"
  target_key_id = aws_kms_key.route53.key_id
}