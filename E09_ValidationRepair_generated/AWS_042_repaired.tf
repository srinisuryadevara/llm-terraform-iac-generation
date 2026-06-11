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

variable "record_set_values" {
  type = list(object({
    name    = string
    type    = string
    ttl     = number
    records = list(string)
  }))
  sensitive = false
}

resource "aws_route53_zone" "primary" {
  name = var.domain_name
  tags = {
    Environment = "production"
    Project     = "route53-hosted-zone"
  }
}

resource "aws_route53_record" "records" {
  for_each = { for record in var.record_set_values : record.name => record }

  zone_id = aws_route53_zone.primary.id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records
  tags = {
    Environment = "production"
    Project     = "route53-hosted-zone"
  }
}

output "route53_zone_id" {
  value       = aws_route53_zone.primary.id
  description = "ID of the Route 53 hosted zone"
}

output "route53_zone_name" {
  value       = aws_route53_zone.primary.name
  description = "Name of the Route 53 hosted zone"
}

output "route53_record_names" {
  value       = [for record in aws_route53_record.records : record.name]
  description = "Names of the Route 53 records"
}

output "route53_record_types" {
  value       = [for record in aws_route53_record.records : record.type]
  description = "Types of the Route 53 records"
}