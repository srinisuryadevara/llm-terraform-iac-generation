provider "aws" {
  region = var.aws_region
}

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

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security Group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [var.subnet_id]

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "rds_instance" {
  identifier           = var.rds_instance_identifier
  instance_class       = var.rds_instance_class
  engine               = "mysql"
  engine_version       = "8.0.28"
  username             = var.rds_database_username
  password             = var.rds_database_password
  database_name        = var.rds_database_name
  port                 = 3306
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  skip_final_snapshot  = true
}