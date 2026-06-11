terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_db_instance" "rds_instance" {
  identifier           = var.rds_identifier
  allocated_storage    = var.rds_allocated_storage
  engine               = var.rds_engine
  engine_version       = var.rds_engine_version
  instance_class       = var.rds_instance_class
  username             = var.rds_username
  password             = var.rds_password
  vpc_security_group_ids = [var.rds_vpc_security_group_id]
  db_subnet_group_name = var.rds_db_subnet_group_name
  publicly_accessible  = false
  storage_encrypted    = true
  kms_key_id           = var.rds_kms_key_id
  deletion_protection  = var.rds_deletion_protection
  skip_final_snapshot  = var.rds_skip_final_snapshot
  tags = {
    Name        = var.rds_name
    Environment = var.rds_environment
  }
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "rds_identifier" {
  type        = string
  sensitive   = true
}

variable "rds_allocated_storage" {
  type        = number
  sensitive   = true
}

variable "rds_engine" {
  type        = string
  sensitive   = true
}

variable "rds_engine_version" {
  type        = string
  sensitive   = true
}

variable "rds_instance_class" {
  type        = string
  sensitive   = true
}

variable "rds_username" {
  type        = string
  sensitive   = true
}

variable "rds_password" {
  type        = string
  sensitive   = true
}

variable "rds_vpc_security_group_id" {
  type        = string
  sensitive   = true
}

variable "rds_db_subnet_group_name" {
  type        = string
  sensitive   = true
}

variable "rds_kms_key_id" {
  type        = string
  sensitive   = true
}

variable "rds_deletion_protection" {
  type        = bool
  sensitive   = true
}

variable "rds_skip_final_snapshot" {
  type        = bool
  sensitive   = true
}

variable "rds_name" {
  type        = string
  sensitive   = true
}

variable "rds_environment" {
  type        = string
  sensitive   = true
}

output "rds_instance_arn" {
  value = aws_db_instance.rds_instance.arn
}

output "rds_instance_endpoint" {
  value = aws_db_instance.rds_instance.endpoint
}

output "rds_instance_status" {
  value = aws_db_instance.rds_instance.status
}