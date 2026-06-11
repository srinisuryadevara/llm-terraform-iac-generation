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

# Create A record with alias to ELB
resource "aws_route53_record" "elb_record" {
  zone_id = data.aws_route53_zone.dns.zone_id
  name    = var.elb_record_name
  type    = "A"
  alias {
    name                   = var.elb_dns_name
    zone_id                = var.elb_zone_id
    evaluate_target_health = true
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "dns_name" {
  type        = string
  description = "DNS name of the hosted zone"
}

variable "a_record_name" {
  type        = string
  description = "Name of the A record"
}

variable "a_record_value" {
  type        = string
  description = "Value of the A record"
}

variable "a_record_ttl" {
  type        = number
  description = "TTL of the A record"
}

variable "cname_record_name" {
  type        = string
  description = "Name of the CNAME record"
}

variable "cname_record_value" {
  type        = string
  description = "Value of the CNAME record"
}

variable "cname_record_ttl" {
  type        = number
  description = "TTL of the CNAME record"
}

variable "elb_record_name" {
  type        = string
  description = "Name of the ELB record"
}

variable "elb_dns_name" {
  type        = string
  description = "DNS name of the ELB"
}

variable "elb_zone_id" {
  type        = string
  description = "Zone ID of the ELB"
}