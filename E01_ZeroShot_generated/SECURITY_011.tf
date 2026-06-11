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
  deletion_protection  = var.rds_deletion_protection
  skip_final_snapshot  = var.rds_skip_final_snapshot
  identifier           = var.rds_identifier
  parameter_group_name = aws_db_parameter_group.rds_parameter_group.name
  storage_encrypted    = true
  kms_key_id          = aws_kms_key.rds_kms_key.arn
  publicly_accessible = false
}

resource "aws_db_parameter_group" "rds_parameter_group" {
  name   = var.rds_parameter_group_name
  family = var.rds_parameter_group_family
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = var.rds_subnet_group_name
  subnet_ids = var.rds_subnet_ids
}

resource "aws_security_group" "rds_sg" {
  name        = var.rds_security_group_name
  description = var.rds_security_group_description
  vpc_id      = var.rds_vpc_id

  ingress {
    from_port   = var.rds_ingress_port
    to_port     = var.rds_ingress_port
    protocol    = var.rds_ingress_protocol
    cidr_blocks = var.rds_ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_kms_key" "rds_kms_key" {
  description             = var.rds_kms_key_description
  deletion_window_in_days = var.rds_kms_deletion_window
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
}

variable "rds_storage_type" {
  type = string
}

variable "rds_deletion_protection" {
  type = bool
}

variable "rds_skip_final_snapshot" {
  type = bool
}

variable "rds_identifier" {
  type = string
}

variable "rds_parameter_group_name" {
  type = string
}

variable "rds_parameter_group_family" {
  type = string
}

variable "rds_subnet_group_name" {
  type = string
}

variable "rds_subnet_ids" {
  type = list(string)
}

variable "rds_security_group_name" {
  type = string
}

variable "rds_security_group_description" {
  type = string
}

variable "rds_vpc_id" {
  type = string
}

variable "rds_ingress_port" {
  type = number
}

variable "rds_ingress_protocol" {
  type = string
}

variable "rds_ingress_cidr_blocks" {
  type = list(string)
}

variable "rds_kms_key_description" {
  type = string
}

variable "rds_kms_deletion_window" {
  type = number
}