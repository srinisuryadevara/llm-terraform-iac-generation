provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
}

variable "db_engine" {
  type        = string
  description = "RDS engine"
}

variable "db_username" {
  type        = string
  sensitive   = true
  description = "RDS username"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "RDS password"
}

variable "db_name" {
  type        = string
  description = "RDS database name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "Allowed CIDR blocks for ingress"
}

resource "aws_db_instance" "this" {
  instance_class = var.db_instance_class
  engine         = var.db_engine
  username       = var.db_username
  password       = var.db_password
  db_name        = var.db_name
  vpc_security_group_ids = [aws_security_group.this.id]
  db_subnet_group_name    = aws_db_subnet_group.this.name
  storage_type            = "gp2"
  storage_encrypted       = true
  publicly_accessible     = false
  skip_final_snapshot     = true

  tags = {
    Name        = "rds-instance"
    Environment = "dev"
  }
}

resource "aws_security_group" "this" {
  name        = "rds-sg"
  description = "RDS security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name        = "rds-sg"
    Environment = "dev"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "rds-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "rds-subnet-group"
    Environment = "dev"
  }
}

output "rds_instance_id" {
  value       = aws_db_instance.this.id
  description = "RDS instance ID"
}

output "rds_instance_arn" {
  value       = aws_db_instance.this.arn
  description = "RDS instance ARN"
}

output "rds_instance_endpoint" {
  value       = aws_db_instance.this.endpoint
  description = "RDS instance endpoint"
}

output "rds_security_group_id" {
  value       = aws_security_group.this.id
  description = "RDS security group ID"
}

output "rds_subnet_group_name" {
  value       = aws_db_subnet_group.this.name
  description = "RDS subnet group name"
}