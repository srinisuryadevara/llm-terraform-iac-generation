variable "domain_name" {
  type        = string
  description = "The domain name for the Route 53 hosted zone"
}

variable "record_name" {
  type        = string
  description = "The name of the record to create"
}

variable "record_type" {
  type        = string
  description = "The type of record to create (e.g. A, CNAME)"
}

variable "record_value" {
  type        = string
  description = "The value of the record to create"
}

variable "alias_name" {
  type        = string
  description = "The name of the alias record"
}

variable "alias_zone_id" {
  type        = string
  description = "The zone ID of the alias record"
}

variable "evaluate_target_health" {
  type        = bool
  description = "Whether to evaluate the health of the target"
}

resource "aws_route53_zone" "example" {
  name = var.domain_name
}

resource "aws_route53_record" "example_a_record" {
  zone_id = aws_route53_zone.example.zone_id
  name    = var.record_name
  type    = "A"
  alias {
    name                   = var.alias_name
    zone_id                = var.alias_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

resource "aws_route53_record" "example_cname_record" {
  zone_id = aws_route53_zone.example.zone_id
  name    = var.record_name
  type    = "CNAME"
  records = [var.record_value]
  ttl     = 60
}