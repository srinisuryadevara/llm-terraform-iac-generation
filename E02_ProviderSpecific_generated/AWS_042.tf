provider "aws" {
  region = var.region
}

resource "aws_route53_zone" "example" {
  name = var.domain_name
}

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.example.id
  name    = var.a_record_name
  type    = "A"
  ttl     = var.ttl
  records = [var.a_record_value]
}

resource "aws_route53_record" "cname_record" {
  zone_id = aws_route53_zone.example.id
  name    = var.cname_record_name
  type    = "CNAME"
  ttl     = var.ttl
  records = [var.cname_record_value]
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "domain_name" {
  type        = string
  description = "Domain name for the hosted zone"
}

variable "a_record_name" {
  type        = string
  description = "Name for the A record"
}

variable "a_record_value" {
  type        = string
  description = "Value for the A record"
}

variable "cname_record_name" {
  type        = string
  description = "Name for the CNAME record"
}

variable "cname_record_value" {
  type        = string
  description = "Value for the CNAME record"
}

variable "ttl" {
  type        = number
  description = "Time to live for the records"
}