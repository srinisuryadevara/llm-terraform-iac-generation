terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  description = "AWS profile"
}

variable "identifier" {
  type        = string
  description = "Identifier for the resources"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "security_group_names" {
  type        = list(string)
  description = "Security group names"
}

variable "instance_type" {
  type        = string
  description = "Instance type"
}

variable "mysql_version" {
  type        = string
  description = "MySQL version"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot"
}

variable "parameters" {
  type        = map(string)
  description = "RDS parameters"
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.identifier}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.identifier} DB subnet group"
  }
}

data "aws_security_group" "security_groups" {
  for_each = toset(var.security_group_names)
  name     = each.value
}

resource "aws_security_group" "allow_mysql" {
  vpc_id = var.vpc_id
  name   = "allow-mysql-${var.identifier}"

  ingress {
    from_port       = 3306
    protocol        = "tcp"
    to_port         = 3306
    security_groups = [for i, g in data.aws_security_group.security_groups : g.id]
  }

  egress {
    from_port       = 0
    protocol        = "-1"
    to_port         = 0
    security_groups = [for i, g in data.aws_security_group.security_groups : g.id]
  }
}

resource "aws_db_parameter_group" "default" {
  family = "mysql8.0"
  name   = "${var.identifier}-parameters"

  dynamic "parameter" {
    for_each = merge(var.parameters, {
      "character_set_server" = "utf8mb4"
      "collation_server"     = "utf8mb4_unicode_ci"
    })
    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "pending-reboot"
    }
  }
}

resource "aws_db_instance" "default" {
  instance_class                        = var.instance_type
  engine                                = "mysql"
  engine_version                        = var.mysql_version
  allocated_storage                     = var.allocated_storage
  max_allocated_storage                 = 60
  skip_final_snapshot                   = var.skip_final_snapshot
  identifier                            = var.identifier
  db_subnet_group_name                  = aws_db_subnet_group.default.name
  parameter_group_name                  = aws_db_parameter_group.default.name
  vpc_security_group_ids                = [aws_security_group.allow_mysql.id]
  publicly_accessible                   = false
  deletion_protection                   = false
}