provider "aws" {
  region = var.region
}

variable "region" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "cname_record_name" {
  type = string
}

variable "cname_record_value" {
  type = string
}

resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.primary.id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = ["192.0.2.1"]
}

resource "aws_route53_record" "cname_record" {
  zone_id = aws_route53_zone.primary.id
  name    = var.cname_record_name
  type    = "CNAME"
  ttl     = 300
  records = [var.cname_record_value]
}