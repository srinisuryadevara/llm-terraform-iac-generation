terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage    = var.allocated_storage
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name = var.db_subnet_group_name
  storage_type         = var.storage_type
  iops                  = var.iops
  publicly_accessible  = false
  deletion_protection  = var.deletion_protection
  skip_final_snapshot  = var.skip_final_snapshot
  storage_encrypted    = true
  kms_key_id           = var.kms_key_id
  apply_immediately    = var.apply_immediately
  backup_retention_period = var.backup_retention_period
  backup_window        = var.backup_window
  maintenance_window   = var.maintenance_window
  parameter_group_name = var.parameter_group_name
  port                 = var.port
  replicate_source_db  = var.replicate_source_db
  tags = {
    Name        = var.db_name
    Environment = var.environment
  }
}

output "rds_instance_arn" {
  value = aws_db_instance.rds_instance.arn
}

output "rds_instance_endpoint" {
  value = aws_db_instance.rds_instance.endpoint
}

output "rds_instance_id" {
  value = aws_db_instance.rds_instance.id
}

output "rds_instance_status" {
  value = aws_db_instance.rds_instance.status
}