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

variable "db_engine" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
  sensitive = true
}

variable "db_name" {
  type = string
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
  count = 2
  vpc_id            = aws_vpc.example.id
  cidr_block        = cidrsubnet(aws_vpc.example.cidr_block, 8, count.index)
  availability_zone = "us-west-2${count.index + 1}"
}

resource "aws_db_subnet_group" "example" {
  name       = "example"
  subnet_ids = aws_subnet.example[*].id
}

resource "aws_security_group" "example" {
  name        = "example"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "example" {
  allocated_storage    = 20
  engine               = var.db_engine
  engine_version       = "13.4"
  instance_class       = var.db_instance_class
  name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  vpc_security_group_ids = [aws_security_group.example.id]
  db_subnet_group_name = aws_db_subnet_group.example.name
}

resource "aws_s3_bucket" "apex-redirect" {
  bucket = "${var.domain}-apex-redirect"
  acl    = "public-read"

  website {
    redirect_all_requests_to = "https://${var.domain}"
  }
}

resource "aws_route53_zone" "externalDnsZone" {
  name = var.externalDnsZone
}

resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.externalDnsZone.id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_s3_bucket.apex-redirect.website_domain
    zone_id                = aws_s3_bucket.apex-redirect.hosted_zone_id
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

resource "aws_route53_record" "dagster" {
  zone_id = aws_route53_zone.externalDnsZone.id
  name    = "dagster"
  type    = "A"

  alias {
    name                   = aws_db_instance.example.address
    zone_id                = aws_db_instance.example.availability_zone
    evaluate_target_health = true
  }
}