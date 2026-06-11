variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_access_key" {
  type        = string
  sensitive   = true
  description = "AWS access key"
}

variable "aws_secret_key" {
  type        = string
  sensitive   = true
  description = "AWS secret key"
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

variable "cname_record_name" {
  type        = string
  description = "Name for the CNAME record"
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.primary.id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [var.a_record_value]
}

resource "aws_route53_record" "cname_record" {
  zone_id = aws_route53_zone.primary.id
  name    = var.cname_record_name
  type    = "CNAME"
  ttl     = 300
  records = [var.cname_record_value]
}