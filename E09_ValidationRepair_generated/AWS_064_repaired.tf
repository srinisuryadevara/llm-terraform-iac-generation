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

variable "record_set_name" {
  type        = string
  sensitive   = false
}

variable "record_set_value" {
  type        = string
  sensitive   = false
}

variable "cname_record_set_name" {
  type        = string
  sensitive   = false
}

variable "cname_record_set_value" {
  type        = string
  sensitive   = false
}

resource "aws_route53_zone" "primary" {
  name = var.domain_name
  tags = {
    Environment = "production"
    Project     = "route53-hosted-zone"
  }
}

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.record_set_name
  type    = "A"
  ttl     = 300
  records = [var.record_set_value]
  tags = {
    Environment = "production"
    Project     = "route53-hosted-zone"
    RecordType  = "A"
  }
}

resource "aws_route53_record" "cname_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.cname_record_set_name
  type    = "CNAME"
  ttl     = 300
  records = [var.cname_record_set_value]
  tags = {
    Environment = "production"
    Project     = "route53-hosted-zone"
    RecordType  = "CNAME"
  }
}

output "zone_id" {
  value = aws_route53_zone.primary.zone_id
}

output "record_set_name" {
  value = aws_route53_record.a_record.name
}

output "cname_record_set_name" {
  value = aws_route53_record.cname_record.name
}