variable "domain" {
  type = string
}

variable "domain_zone_id" {
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

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "DB Subnet Group"
  }
}

resource "aws_db_instance" "db_instance" {
  identifier           = "db-instance"
  instance_class       = var.db_instance_class
  engine               = "postgres"
  engine_version       = "13.4"
  username             = var.db_username
  password             = var.db_password
  db_name              = var.db_name
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
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

resource "aws_alb" "alb" {
  name            = var.alb_name
  subnets         = var.alb_subnets
  security_groups = var.alb_security_groups

  tags = {
    Name = "ALB"
  }
}

resource "aws_route53_zone" "route53_zone" {
  name = var.domain
}

resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.route53_zone.id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "cname_record" {
  zone_id = aws_route53_zone.route53_zone.id
  name    = "www.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["global-nossl.fastly.net"]
}