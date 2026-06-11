provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project Name"
}

variable "environment" {
  type        = string
  description = "Environment Name"
}

variable "db_instance_class" {
  type        = string
  description = "RDS Instance Class"
}

variable "db_engine" {
  type        = string
  description = "RDS Engine"
}

variable "db_username" {
  type        = string
  sensitive   = true
  description = "RDS Username"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "RDS Password"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet CIDR"
}

variable "db_port" {
  type        = number
  description = "RDS Port"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_subnet" "this" {
  cidr_block = var.subnet_cidr
  vpc_id     = aws_vpc.this.id
  availability_zone = "${var.region}a"
  tags = {
    Name        = "${var.project}-${var.environment}-subnet"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = [aws_subnet.this.id]
  tags = {
    Name        = "${var.project}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_db_instance" "this" {
  instance_class = var.db_instance_class
  engine         = var.db_engine
  username       = var.db_username
  password       = var.db_password
  port           = var.db_port
  vpc_security_group_ids = [aws_security_group.this.id]
  db_subnet_group_name    = aws_db_subnet_group.this.name
  storage_type           = "gp2"
  storage_encrypted      = true
  publicly_accessible    = false
  skip_final_snapshot    = true
  tags = {
    Name        = "${var.project}-${var.environment}-db-instance"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_security_group" "this" {
  name        = "${var.project}-${var.environment}-db-sg"
  description = "Allow inbound traffic to the DB instance"
  vpc_id      = aws_vpc.this.id
  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  tags = {
    Name        = "${var.project}-${var.environment}-db-sg"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_kms_key" "this" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  tags = {
    Name        = "${var.project}-${var.environment}-kms-key"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.project}-${var.environment}-kms-key"
  target_key_id = aws_kms_key.this.key_id
}