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

variable "subdomain_name" {
  type        = string
  sensitive   = false
}

variable "ip_address" {
  type        = string
  sensitive   = false
}

resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.subdomain_name
  type    = "A"
  ttl     = 300
  records = [var.ip_address]
}

resource "aws_route53_record" "cname_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.${var.subdomain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.subdomain_name]
}