# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Get already publicly configured Hosted Zone on Route53 - MUST EXIST
data "aws_route53_zone" "dns" {
  name = var.dns_name
}

# Create A record in hosted zone
resource "aws_route53_record" "a_record" {
  zone_id = data.aws_route53_zone.dns.zone_id
  name    = var.a_record_name
  type    = "A"
  ttl     = var.a_record_ttl
  records = [var.a_record_value]
}

# Create CNAME record in hosted zone
resource "aws_route53_record" "cname_record" {
  zone_id = data.aws_route53_zone.dns.zone_id
  name    = var.cname_record_name
  type    = "CNAME"
  ttl     = var.cname_record_ttl
  records = [var.cname_record_value]
}

# Create A record with alias to ALB
resource "aws_route53_record" "alb_record" {
  zone_id = data.aws_route53_zone.dns.zone_id
  name    = var.alb_record_name
  type    = "A"
  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "dns_name" {
  type        = string
  description = "DNS Name"
}

variable "a_record_name" {
  type        = string
  description = "A Record Name"
}

variable "a_record_value" {
  type        = string
  description = "A Record Value"
}

variable "a_record_ttl" {
  type        = number
  description = "A Record TTL"
}

variable "cname_record_name" {
  type        = string
  description = "CNAME Record Name"
}

variable "cname_record_value" {
  type        = string
  description = "CNAME Record Value"
}

variable "cname_record_ttl" {
  type        = number
  description = "CNAME Record TTL"
}

variable "alb_record_name" {
  type        = string
  description = "ALB Record Name"
}

variable "alb_dns_name" {
  type        = string
  description = "ALB DNS Name"
}

variable "alb_zone_id" {
  type        = string
  description = "ALB Zone ID"
}