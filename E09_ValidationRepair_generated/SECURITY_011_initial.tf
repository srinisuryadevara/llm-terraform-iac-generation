provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "rds_instance_identifier" {
  type        = string
  description = "RDS Instance Identifier"
}

variable "rds_instance_class" {
  type        = string
  description = "RDS Instance Class"
}

variable "rds_engine" {
  type        = string
  description = "RDS Engine"
}

variable "rds_username" {
  type        = string
  sensitive   = true
  description = "RDS Username"
}

variable "rds_password" {
  type        = string
  sensitive   = true
  description = "RDS Password"
}

variable "rds_vpc_security_group_ids" {
  type        = list(string)
  description = "RDS VPC Security Group IDs"
}

variable "rds_subnet_group_name" {
  type        = string
  description = "RDS Subnet Group Name"
}

variable "rds_kms_key_id" {
  type        = string
  description = "RDS KMS Key ID"
}

resource "aws_db_instance" "this" {
  identifier           = var.rds_instance_identifier
  instance_class       = var.rds_instance_class
  engine               = var.rds_engine
  username             = var.rds_username
  password             = var.rds_password
  vpc_security_group_ids = var.rds_vpc_security_group_ids
  db_subnet_group_name = var.rds_subnet_group_name
  storage_type         = "gp2"
  storage_encrypted    = true
  kms_key_id           = var.rds_kms_key_id
  publicly_accessible  = false
  deletion_protection  = false
}