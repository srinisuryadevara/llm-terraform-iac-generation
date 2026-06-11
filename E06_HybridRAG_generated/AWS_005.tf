variable "domain_name" {
  type        = string
  description = "The domain name for the hosted zone"
}

variable "record_name" {
  type        = string
  description = "The name of the record"
}

variable "record_value" {
  type        = string
  description = "The value of the record"
}

variable "cname_record_name" {
  type        = string
  description = "The name of the CNAME record"
}

variable "cname_record_value" {
  type        = string
  description = "The value of the CNAME record"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_route53_zone" "example" {
  name = var.domain_name
}

resource "aws_route53_record" "example_a_record" {
  zone_id = aws_route53_zone.example.zone_id
  name    = var.record_name
  type    = "A"
  ttl     = 60
  records = [var.record_value]
}

resource "aws_route53_record" "example_cname_record" {
  zone_id = aws_route53_zone.example.zone_id
  name    = var.cname_record_name
  type    = "CNAME"
  ttl     = 60
  records = [var.cname_record_value]
}