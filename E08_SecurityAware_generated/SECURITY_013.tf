provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
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

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "db_subnet_cidr" {
  type        = string
  description = "DB subnet CIDR"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_subnet" "db" {
  cidr_block = var.db_subnet_cidr
  vpc_id     = aws_vpc.this.id
  availability_zone = "${var.region}a"
  tags = {
    Name        = "${var.project}-${var.environment}-db-subnet"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = [aws_subnet.db.id]
  tags = {
    Name        = "${var.project}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_kms_key" "this" {
  description             = "${var.project}-${var.environment}-rds-kms-key"
  deletion_window_in_days = 10
  tags = {
    Name        = "${var.project}-${var.environment}-rds-kms-key"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_db_instance" "this" {
  allocated_storage    = 20
  engine               = var.db_engine
  engine_version       = "14.03"
  instance_class       = var.db_instance_class
  username             = var.db_username
  password             = var.db_password
  vpc_security_group_ids = [aws_security_group.this.id]
  db_subnet_group_name = aws_db_subnet_group.this.name
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.this.arn
  publicly_accessible  = false
  skip_final_snapshot  = true
  tags = {
    Name        = "${var.project}-${var.environment}-rds-instance"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_security_group" "this" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "RDS security group"
  vpc_id      = aws_vpc.this.id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.db_subnet_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.project}-${var.environment}-rds-sg"
    Environment = var.environment
    Project     = var.project
  }
}