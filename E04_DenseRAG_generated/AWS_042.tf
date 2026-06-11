variable "domain" {
  type = string
}

variable "domain_zone_id" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "alb_zone_id" {
  type = string
}

variable "s3_bucket_website_domain" {
  type = string
}

variable "s3_bucket_hosted_zone_id" {
  type = string
}

resource "aws_route53_zone" "example" {
  name = var.domain
}

resource "aws_route53_record" "example_a_record" {
  zone_id = aws_route53_zone.example.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "example_cname_record" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "www.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["global-nossl.fastly.net"]
}

resource "aws_route53_record" "example_apex_record" {
  zone_id = aws_route53_zone.example.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = var.s3_bucket_website_domain
    zone_id                = var.s3_bucket_hosted_zone_id
    evaluate_target_health = true
  }
}