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

variable "db_instance_class" {
  type        = string
  description = "DB Instance Class"
}

variable "db_instance_identifier" {
  type        = string
  description = "DB Instance Identifier"
}

variable "db_username" {
  type        = string
  sensitive   = true
  description = "DB Username"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "DB Password"
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
  identifier           = var.db_instance_identifier
  instance_class       = var.db_instance_class
  engine               = "mysql"
  engine_version       = "8.0.23"
  username             = var.db_username
  password             = var.db_password
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  storage_type         = "gp2"
  allocated_storage    = 20
  skip_final_snapshot  = true
}