provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone
  tags = {
    Name = var.private_subnet_name
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
  vpc_id = aws_vpc.main.id
  name   = "allow-mysql-${var.identifier}"

  ingress {
    from_port       = 3306
    protocol        = "tcp"
    to_port         = 3306
    cidr_blocks     = [var.vpc_cidr]
  }

  egress {
    from_port       = 0
    protocol        = "-1"
    to_port         = 0
    cidr_blocks     = ["0.0.0.0/0"]
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
  username                              = var.db_username
  password                              = var.db_password
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
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  description = "AWS profile"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "vpc_name" {
  type        = string
  description = "VPC name"
}

variable "private_subnet_cidr" {
  type        = string
  description = "Private subnet CIDR"
}

variable "private_subnet_name" {
  type        = string
  description = "Private subnet name"
}

variable "availability_zone" {
  type        = string
  description = "Availability zone"
}

variable "identifier" {
  type        = string
  description = "Identifier"
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

variable "db_username" {
  type        = string
  description = "DB username"
}

variable "db_password" {
  type        = string
  description = "DB password"
  sensitive   = true
}

variable "parameters" {
  type        = map(string)
  description = "DB parameters"
  default     = {}
}

locals {
  default_parameters = {
    "character_set_server" = "utf8mb4"
    "collation_server"    = "utf8mb4_unicode_ci"
  }
}