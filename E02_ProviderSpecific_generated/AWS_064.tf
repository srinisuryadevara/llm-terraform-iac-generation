provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "domain_name" {
  type        = string
  description = "Domain name for the hosted zone"
}

variable "a_record_value" {
  type        = string
  description = "Value for the A record"
}

variable "cname_record_value" {
  type        = string
  description = "Value for the CNAME record"
}

resource "aws_route53_zone" "example" {
  name = var.domain_name
}

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.example.zone_id
  name     = "example"
  type     = "A"
  ttl      = 300
  records  = [var.a_record_value]
}

resource "aws_route53_record" "cname_record" {
  zone_id = aws_route53_zone.example.zone_id
  name     = "cname"
  type     = "CNAME"
  ttl      = 300
  records  = [var.cname_record_value]
}