variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_access_key" {
  type        = string
  sensitive   = true
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  type        = string
  sensitive   = true
  description = "AWS Secret Key"
}

variable "domain_name" {
  type        = string
  description = "Domain Name"
}

variable "a_record_ip" {
  type        = string
  description = "A Record IP"
}

variable "cname_record_name" {
  type        = string
  description = "CNAME Record Name"
}

variable "cname_record_value" {
  type        = string
  description = "CNAME Record Value"
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
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [var.a_record_ip]
}

resource "aws_route53_record" "cname_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.cname_record_name
  type    = "CNAME"
  ttl     = 300
  records = [var.cname_record_value]
}