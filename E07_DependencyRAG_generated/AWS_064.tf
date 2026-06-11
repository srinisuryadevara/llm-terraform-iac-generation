variable "domain" {
  type = string
}

variable "externalDnsZone" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "db_instance_class" {
  type = string
}

variable "db_username" {
  type = string
  sensitive = true
}

variable "db_password" {
  type = string
  sensitive = true
}

variable "db_name" {
  type = string
}

variable "alb_name" {
  type = string
}

variable "alb_subnets" {
  type = list(string)
}

variable "alb_security_groups" {
  type = list(string)
}

resource "aws_route53_zone" "externalDnsZone" {
  name = var.externalDnsZone
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "DB Subnet Group"
  }
}

resource "aws_security_group" "db_security_group" {
  name        = "db-security-group"
  description = "Security group for DB instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DB Security Group"
  }
}

resource "aws_db_instance" "db_instance" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = var.db_instance_class
  name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
}

resource "aws_alb" "alb" {
  name            = var.alb_name
  subnets         = var.alb_subnets
  security_groups = var.alb_security_groups

  tags = {
    Name = "ALB"
  }
}

resource "aws_route53_record" "dagster" {
  zone_id = aws_route53_zone.externalDnsZone.id
  name    = "dagster"
  type    = "A"

  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.externalDnsZone.id
  name    = "www.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["global-nossl.fastly.net"]
}

resource "aws_s3_bucket" "apex_redirect" {
  bucket = var.domain

  website {
    redirect_all_requests_to = "https://www.${var.domain}"
  }
}

resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.externalDnsZone.id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_s3_bucket.apex_redirect.website_endpoint
    zone_id                = aws_s3_bucket.apex_redirect.hosted_zone_id
    evaluate_target_health = true
  }
}