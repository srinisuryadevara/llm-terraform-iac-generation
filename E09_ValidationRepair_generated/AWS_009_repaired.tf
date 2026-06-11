provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "aws_access_key" {
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  type        = string
  sensitive   = false
}

variable "subnet_id" {
  type        = string
  sensitive   = false
}

variable "db_instance_class" {
  type        = string
  default     = "db.t2.micro"
}

variable "db_instance_identifier" {
  type        = string
  default     = "mysql-rds-instance"
}

variable "db_username" {
  type        = string
  sensitive   = true
}

variable "db_password" {
  type        = string
  sensitive   = true
}

variable "db_name" {
  type        = string
  default     = "mysql_db"
}

resource "aws_db_instance" "mysql_rds" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.28"
  instance_class       = var.db_instance_class
  identifier           = var.db_instance_identifier
  username             = var.db_username
  password             = var.db_password
  db_name              = var.db_name
  parameter_group_name = "default.mysql8.0"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  publicly_accessible    = false
  skip_final_snapshot     = true
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # restrict to private subnet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"] # restrict to private subnet
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [var.subnet_id]

  tags = {
    Name = "RDS Subnet Group"
  }
}

output "rds_instance_id" {
  value       = aws_db_instance.mysql_rds.id
  description = "RDS instance ID"
}

output "rds_instance_arn" {
  value       = aws_db_instance.mysql_rds.arn
  description = "RDS instance ARN"
}

output "rds_instance_endpoint" {
  value       = aws_db_instance.mysql_rds.endpoint
  description = "RDS instance endpoint"
}

output "rds_security_group_id" {
  value       = aws_security_group.rds_sg.id
  description = "RDS security group ID"
}

output "rds_subnet_group_name" {
  value       = aws_db_subnet_group.rds_subnet_group.name
  description = "RDS subnet group name"
}