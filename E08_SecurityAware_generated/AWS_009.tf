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

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "Private subnet ID"
}

variable "ssh_cidr" {
  type        = string
  description = "SSH allowed CIDR"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
}

variable "db_username" {
  type        = string
  description = "RDS username"
  sensitive   = true
}

variable "db_password" {
  type        = string
  description = "RDS password"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "RDS database name"
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "RDS security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [
      var.ssh_cidr,
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-rds-sg"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_db_instance" "rds_instance" {
  identifier           = "${var.project}-${var.environment}-rds"
  instance_class       = var.db_instance_class
  engine               = "mysql"
  engine_version       = "8.0.28"
  username             = var.db_username
  password             = var.db_password
  db_name              = var.db_name
  parameter_group_name = "default.mysql8.0"
  vpc_security_group_ids = [
    aws_security_group.rds_sg.id,
  ]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  storage_type         = "gp2"
  allocated_storage    = 20
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.rds_kms_key.arn
  deletion_protection  = false
  skip_final_snapshot  = true

  tags = {
    Name        = "${var.project}-${var.environment}-rds"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project}-${var.environment}-rds-subnet-group"
  subnet_ids = [var.subnet_id]

  tags = {
    Name        = "${var.project}-${var.environment}-rds-subnet-group"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_kms_key" "rds_kms_key" {
  description             = "RDS KMS key"
  deletion_window_in_days = 10

  tags = {
    Name        = "${var.project}-${var.environment}-rds-kms-key"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_kms_alias" "rds_kms_alias" {
  name          = "alias/${var.project}-${var.environment}-rds-kms-key"
  target_key_id = aws_kms_key.rds_kms_key.key_id
}