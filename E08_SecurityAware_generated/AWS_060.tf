variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "project_name" {
  type        = string
  description = "Project Name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "key_alias" {
  type        = string
  description = "KMS Key Alias"
}

variable "key_description" {
  type        = string
  description = "KMS Key Description"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_kms_key" "this" {
  description             = var.key_description
  deletion_window_in_days = 10
  tags = {
    Name        = var.key_alias
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_kms_alias" "this" {
  name          = var.key_alias
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