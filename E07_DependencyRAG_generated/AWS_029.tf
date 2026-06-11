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
  profile = "default"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
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
  description = "MySQL parameters"
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
    for_each = var.parameters
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
  db_subnet_group_name                  = aws_db_subnet_group.default.name
  vpc_security_group_ids                = [aws_security_group.allow_mysql.id]
  parameter_group_name                  = aws_db_parameter_group.default.name
  publicly_accessible                   = false
  deletion_protection                   = false
}

resource "aws_subnet" "private" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.identifier} private subnet"
  }
}

resource "aws_instance" "example" {
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id
  vpc_security_group_ids = [
    aws_security_group.allow_mysql.id
  ]

  tags = {
    Name = "${var.identifier} example instance"
  }
}