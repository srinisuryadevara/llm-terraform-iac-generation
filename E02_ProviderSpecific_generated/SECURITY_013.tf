provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "db_instance_identifier" {
  type        = string
  sensitive   = false
}

variable "db_instance_class" {
  type        = string
  sensitive   = false
}

variable "db_engine" {
  type        = string
  sensitive   = false
}

variable "db_username" {
  type        = string
  sensitive   = true
}

variable "db_password" {
  type        = string
  sensitive   = true
}

variable "db_subnet_group_name" {
  type        = string
  sensitive   = false
}

variable "vpc_security_group_ids" {
  type        = list(string)
  sensitive   = false
}

resource "aws_db_instance" "example" {
  identifier           = var.db_instance_identifier
  instance_class         = var.db_instance_class
  engine                 = var.db_engine
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  storage_type           = "gp2"
  encrypted              = true
  kms_key_id             = aws_kms_key.example.arn
  publicly_accessible   = false
}

resource "aws_kms_key" "example" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
}

resource "aws_kms_key_policy" "example" {
  kms_key_id = aws_kms_key.example.key_id
  policy     = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "kms:*"
        Resource = "*"
      },
    ]
  })
}

data "aws_caller_identity" "current" {}