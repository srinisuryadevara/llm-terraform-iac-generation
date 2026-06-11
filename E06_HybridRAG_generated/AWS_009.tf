variable "aws_region" {
  type        = string
  default     = "us-west-2"
}

variable "vpc_id" {
  type        = string
}

variable "private_subnet_id" {
  type        = string
}

variable "rds_instance_class" {
  type        = string
  default     = "db.t2.micro"
}

variable "rds_engine_version" {
  type        = string
  default     = "8.0.20"
}

variable "rds_username" {
  type        = string
  sensitive   = true
}

variable "rds_password" {
  type        = string
  sensitive   = true
}

variable "rds_database_name" {
  type        = string
  default     = "mydb"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = var.rds_engine_version
  instance_class       = var.rds_instance_class
  name                 = var.rds_database_name
  username             = var.rds_username
  password             = var.rds_password
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name = aws_db_subnet_group.rds.name
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = [var.private_subnet_id]

  tags = {
    Name = "RDS Subnet Group"
  }
}