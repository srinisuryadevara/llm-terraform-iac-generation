provider "aws" {
  region = var.aws_region
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage    = var.rds_allocated_storage
  engine              = var.rds_engine
  engine_version       = var.rds_engine_version
  instance_class       = var.rds_instance_class
  username             = var.rds_username
  password             = var.rds_password
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  storage_type         = var.rds_storage_type
  backup_retention_period = var.rds_backup_retention_period
  skip_final_snapshot  = var.rds_skip_final_snapshot
  deletion_protection  = var.rds_deletion_protection
  storage_encrypted    = true
  kms_key_id          = aws_kms_key.rds_kms_key.arn
  publicly_accessible  = false
}

resource "aws_kms_key" "rds_kms_key" {
  description             = "KMS key for RDS instance"
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "rds_kms_alias" {
  name          = "alias/rds-kms-key"
  target_key_id = aws_kms_key.rds_kms_key.key_id
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = var.rds_subnet_ids
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "aws_region" {
  type = string
}

variable "rds_allocated_storage" {
  type = number
}

variable "rds_engine" {
  type = string
}

variable "rds_engine_version" {
  type = string
}

variable "rds_instance_class" {
  type = string
}

variable "rds_username" {
  type = string
}

variable "rds_password" {
  type = string
  sensitive = true
}

variable "rds_storage_type" {
  type = string
}

variable "rds_backup_retention_period" {
  type = number
}

variable "rds_skip_final_snapshot" {
  type = bool
}

variable "rds_deletion_protection" {
  type = bool
}

variable "rds_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}