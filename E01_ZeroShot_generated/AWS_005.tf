provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "domain_name" {
  type        = string
  sensitive   = false
}

variable "aws_access_key" {
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  sensitive   = true
}

resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "test"
  type    = "A"
  ttl     = "300"
  records = ["192.0.2.1"]
}

resource "aws_route53_record" "cname_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "blog"
  type    = "CNAME"
  ttl     = "300"
  records = ["example.com"]
}