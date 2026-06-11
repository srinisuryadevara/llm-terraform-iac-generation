provider "aws" {
  region = var.region
}

variable "region" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "record_set_name" {
  type = string
}

variable "record_set_value" {
  type = string
}

resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.primary.id
  name    = var.record_set_name
  type    = "A"
  ttl     = 300
  records = [var.record_set_value]
}

resource "aws_route53_record" "cname_record" {
  zone_id = aws_route53_zone.primary.id
  name    = "cname"
  type    = "CNAME"
  ttl     = 300
  records = [var.record_set_value]
}