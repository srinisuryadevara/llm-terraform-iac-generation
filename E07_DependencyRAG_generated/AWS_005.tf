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

variable "db_instance_identifier" {
  type = string
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

variable "db_port" {
  type = number
}

variable "security_group_name" {
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

variable "alb_target_group_name" {
  type = string
}

variable "alb_target_group_port" {
  type = number
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "DB Subnet Group"
  }
}

resource "aws_db_instance" "db_instance" {
  identifier           = var.db_instance_identifier
  instance_class       = var.db_instance_class
  engine               = var.db_engine
  username             = var.db_username
  password             = var.db_password
  port                 = var.db_port
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.security_group.id]
}

resource "aws_security_group" "security_group" {
  name        = var.security_group_name
  description = "Security group for DB instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
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

resource "aws_alb_target_group" "alb_target_group" {
  name     = var.alb_target_group_name
  port     = var.alb_target_group_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/"
    port                = var.alb_target_group_port
  }

  tags = {
    Name = "ALB Target Group"
  }
}

resource "aws_route53_zone" "route53_zone" {
  name = var.domain
}

resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.route53_zone.id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.route53_zone.id
  name    = "www.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["global-nossl.fastly.net"]
}