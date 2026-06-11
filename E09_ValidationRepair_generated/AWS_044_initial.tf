provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "aws_access_key" {
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  sensitive   = true
}

variable "domain_name" {
  type        = string
}

variable "record_name" {
  type        = string
}

variable "record_value" {
  type        = string
}

variable "cname_record_name" {
  type        = string
}

variable "cname_record_value" {
  type        = string
}

resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.record_name
  type    = "A"
  ttl     = 300
  records = [var.record_value]
}

resource "aws_route53_record" "cname_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.cname_record_name
  type    = "CNAME"
  ttl     = 300
  records = [var.cname_record_value]
}

output "zone_id" {
  value = aws_route53_zone.primary.zone_id
}

output "a_record_name" {
  value = aws_route53_record.a_record.name
}

output "cname_record_name" {
  value = aws_route53_record.cname_record.name
}