# Get already publicly configured Hosted Zone on Route53 - MUST EXIST
data "aws_route53_zone" "dns" {
  provider = aws.region-master
  name     = var.dns-name
}

# Create A record in hosted zone
resource "aws_route53_record" "a_record" {
  provider = aws.region-master
  zone_id  = data.aws_route53_zone.dns.zone_id
  name     = var.a_record_name
  type     = "A"
  ttl      = var.a_record_ttl
  records  = [var.a_record_value]
}

# Create CNAME record in hosted zone
resource "aws_route53_record" "cname_record" {
  provider = aws.region-master
  zone_id  = data.aws_route53_zone.dns.zone_id
  name     = var.cname_record_name
  type     = "CNAME"
  ttl      = var.cname_record_ttl
  records  = [var.cname_record_value]
}

# Create Alias record towards ALB from Route53
resource "aws_route53_record" "alias_record" {
  provider = aws.region-master
  zone_id  = data.aws_route53_zone.dns.zone_id
  name     = var.alias_record_name
  type     = "A"
  alias {
    name                   = aws_lb.application-lb.dns_name
    zone_id                = aws_lb.application-lb.zone_id
    evaluate_target_health = true
  }
}

variable "dns-name" {
  type        = string
  description = "The name of the hosted zone"
}

variable "a_record_name" {
  type        = string
  description = "The name of the A record"
}

variable "a_record_ttl" {
  type        = number
  description = "The TTL of the A record"
}

variable "a_record_value" {
  type        = string
  description = "The value of the A record"
}

variable "cname_record_name" {
  type        = string
  description = "The name of the CNAME record"
}

variable "cname_record_ttl" {
  type        = number
  description = "The TTL of the CNAME record"
}

variable "cname_record_value" {
  type        = string
  description = "The value of the CNAME record"
}

variable "alias_record_name" {
  type        = string
  description = "The name of the alias record"
}