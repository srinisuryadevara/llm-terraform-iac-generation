provider "aws" {
  region = var.aws_region
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage    = var.rds_allocated_storage
  engine               = var.rds_engine
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
  publicly_accessible  = false
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.rds_kms_key.arn
}

resource "aws_security_group" "rds_sg" {
  name        = var.rds_sg_name
  description = var.rds_sg_description
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.rds_port
    to_port     = var.rds_port
    protocol    = "tcp"
    cidr_blocks = var.rds_sg_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.rds_sg_name
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = var.rds_subnet_group_name
  subnet_ids = var.rds_subnet_ids

  tags = {
    Name = var.rds_subnet_group_name
  }
}

resource "aws_kms_key" "rds_kms_key" {
  description             = var.rds_kms_key_description
  deletion_window_in_days = var.rds_kms_key_deletion_window
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "rds_allocated_storage" {
  type        = number
  default     = 20
}

variable "rds_engine" {
  type        = string
  default     = "postgres"
}

variable "rds_engine_version" {
  type        = string
  default     = "13.4"
}

variable "rds_instance_class" {
  type        = string
  default     = "db.t2.micro"
}

variable "rds_username" {
  type        = string
  sensitive   = true
}

variable "rds_password" {
  type        = string
  sensitive   = true
}

variable "rds_storage_type" {
  type        = string
  default     = "gp2"
}

variable "rds_backup_retention_period" {
  type        = number
  default     = 7
}

variable "rds_skip_final_snapshot" {
  type        = bool
  default     = true
}

variable "rds_deletion_protection" {
  type        = bool
  default     = false
}

variable "rds_port" {
  type        = number
  default     = 5432
}

variable "rds_sg_name" {
  type        = string
  default     = "rds-sg"
}

variable "rds_sg_description" {
  type        = string
  default     = "Security group for RDS instance"
}

variable "vpc_id" {
  type        = string
  sensitive   = true
}

variable "rds_sg_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "rds_subnet_group_name" {
  type        = string
  default     = "rds-subnet-group"
}

variable "rds_subnet_ids" {
  type        = list(string)
  sensitive   = true
}

variable "rds_kms_key_description" {
  type        = string
  default     = "KMS key for RDS instance"
}

variable "rds_kms_key_deletion_window" {
  type        = number
  default     = 10
}