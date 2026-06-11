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

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
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
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.mysql_subnet_group.name
  publicly_accessible    = false
}

resource "aws_security_group" "mysql_sg" {
  name        = "mysql-sg"
  description = "Security group for MySQL RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow MySQL connection"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "mysql_subnet_group" {
  name       = "mysql-subnet-group"
  subnet_ids = [var.subnet_id]

  tags = {
    Name = "MySQL Subnet Group"
  }
}

output "db_instance_id" {
  value       = aws_db_instance.mysql_rds.id
  description = "The ID of the RDS instance"
}

output "db_instance_arn" {
  value       = aws_db_instance.mysql_rds.arn
  description = "The ARN of the RDS instance"
}

output "db_instance_endpoint" {
  value       = aws_db_instance.mysql_rds.endpoint
  description = "The endpoint of the RDS instance"
}

output "db_security_group_id" {
  value       = aws_security_group.mysql_sg.id
  description = "The ID of the security group"
}