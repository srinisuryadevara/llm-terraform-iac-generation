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
  identifier           = var.identifier
  allocated_storage    = var.allocated_storage
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  username             = var.username
  password             = var.password
  parameter_group_name = var.parameter_group_name
  publicly_accessible  = false
  vpc_security_group_ids = [var.vpc_security_group_id]
  db_subnet_group_name   = var.db_subnet_group_name
  storage_type          = var.storage_type
  iops                  = var.iops
  multi_az              = var.multi_az
  deletion_protection   = var.deletion_protection
  skip_final_snapshot   = var.skip_final_snapshot
  storage_encrypted     = true
  kms_key_id            = var.kms_key_id
  tags = {
    Name        = var.name
    Environment = var.environment
  }
}

output "rds_instance_address" {
  value = aws_db_instance.rds_instance.address
}

output "rds_instance_arn" {
  value = aws_db_instance.rds_instance.arn
}

output "rds_instance_id" {
  value = aws_db_instance.rds_instance.id
}

output "rds_instance_endpoint" {
  value = aws_db_instance.rds_instance.endpoint
}

output "rds_instance_status" {
  value = aws_db_instance.rds_instance.status
}