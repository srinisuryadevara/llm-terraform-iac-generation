variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID"
}

variable "rds_instance_class" {
  type        = string
  description = "RDS Instance Class"
}

variable "rds_instance_identifier" {
  type        = string
  description = "RDS Instance Identifier"
}

variable "rds_database_name" {
  type        = string
  description = "RDS Database Name"
}

variable "rds_database_username" {
  type        = string
  description = "RDS Database Username"
}

variable "rds_database_password" {
  type        = string
  sensitive   = true
  description = "RDS Database Password"
}

variable "rds_port" {
  type        = number
  description = "RDS Port"
}

variable "rds_engine" {
  type        = string
  description = "RDS Engine"
}

variable "rds_engine_version" {
  type        = string
  description = "RDS Engine Version"
}

variable "rds_allocated_storage" {
  type        = number
  description = "RDS Allocated Storage"
}

variable "rds_storage_type" {
  type        = string
  description = "RDS Storage Type"
}

variable "rds_parameter_group_name" {
  type        = string
  description = "RDS Parameter Group Name"
}

variable "rds_option_group_name" {
  type        = string
  description = "RDS Option Group Name"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "RDS Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port = var.rds_port
    to_port   = var.rds_port
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = [var.subnet_id]

  tags = {
    Name = "RDS Subnet Group"
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage               = var.rds_allocated_storage
  storage_type                    = var.rds_storage_type
  engine                          = var.rds_engine
  engine_version                  = var.rds_engine_version
  instance_class                  = var.rds_instance_class
  name                            = var.rds_database_name
  username                        = var.rds_database_username
  password                        = var.rds_database_password
  port                            = var.rds_port
  db_subnet_group_name            = aws_db_subnet_group.rds.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  identifier                      = var.rds_instance_identifier
  parameter_group_name            = var.rds_parameter_group_name
  option_group_name               = var.rds_option_group_name
  multi_az                        = false
  publicly_accessible             = false
  skip_final_snapshot             = true
  deletion_protection             = false
  backup_retention_period         = 7
  backup_window                   = "02:00-03:00"
  maintenance_window              = "Sat:03:00-Sat:04:00"
  apply_immediately               = true
}