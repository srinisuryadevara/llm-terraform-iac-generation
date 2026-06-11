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

resource "aws_vpc" "default" {
  cidr_block = var.cidr_block
  tags = {
    Name = var.identifier
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.private_cidr_block
  availability_zone = var.availability_zone
  tags = {
    Name = "${var.identifier}-private-subnet"
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.identifier}-db-subnet-group"
  subnet_ids = [aws_subnet.private.id]

  tags = {
    Name = "${var.identifier} DB subnet group"
  }
}

resource "aws_security_group" "allow_mysql" {
  vpc_id = aws_vpc.default.id
  name   = "allow-mysql-${var.identifier}"

  ingress {
    from_port   = 3306
    protocol    = "tcp"
    to_port     = 3306
    cidr_blocks = [var.cidr_block]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
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
  vpc_security_group_ids                = [aws_security_group.allow_mysql.id]
  db_instance_port                      = 3306
  parameter_group_name                  = aws_db_parameter_group.default.name
}

resource "aws_db_parameter_group" "default" {
  family = "mysql8.0"
  name   = "${var.identifier}-parameters"

  dynamic "parameter" {
    for_each = merge(var.parameters, local.default_parameters)
    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "pending-reboot"
    }
  }
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_profile" {
  type        = string
  description = "AWS Profile"
}

variable "identifier" {
  type        = string
  description = "Identifier for resources"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for VPC"
}

variable "private_cidr_block" {
  type        = string
  description = "CIDR block for private subnet"
}

variable "availability_zone" {
  type        = string
  description = "Availability zone for subnet"
}

variable "instance_type" {
  type        = string
  description = "Instance type for RDS instance"
}

variable "mysql_version" {
  type        = string
  description = "MySQL version for RDS instance"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage for RDS instance"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot for RDS instance"
}

variable "parameters" {
  type        = map(string)
  description = "Parameters for RDS instance"
  default     = {}
}

locals {
  default_parameters = {
    "character_set_server" = "utf8mb4"
    "collation_server"     = "utf8mb4_unicode_ci"
  }
}