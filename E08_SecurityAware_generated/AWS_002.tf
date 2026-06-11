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

variable "key_alias" {
  type        = string
  description = "KMS key alias"
}

variable "key_description" {
  type        = string
  description = "KMS key description"
}

resource "aws_kms_key" "this" {
  description             = var.key_description
  deletion_window_in_days = 10
  tags = {
    Name        = var.key_alias
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.key_alias}"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_kms_key_policy" "this" {
  key_id = aws_kms_key.this.key_id
  policy = jsonencode({
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
      {
        Effect = "Allow"
        Principal = {
          Service = "kms.amazonaws.com"
        }
        Action = "kms:GenerateDataKey"
        Resource = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {
}