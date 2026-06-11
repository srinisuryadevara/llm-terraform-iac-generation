provider "aws" {
  region = var.aws_region
}

resource "aws_kms_key" "example" {
  description             = var.kms_key_description
  deletion_window_in_days = var.deletion_window_in_days
}

resource "aws_kms_alias" "example" {
  name          = var.kms_alias_name
  target_key_id = aws_kms_key.example.key_id
}

resource "aws_kms_key_policy" "example" {
  key_id = aws_kms_key.example.key_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.kms_key_admin_arn
        }
        Action = "kms:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = var.kms_key_user_arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "kms_key_description" {
  type        = string
  sensitive   = true
}

variable "deletion_window_in_days" {
  type        = number
  sensitive   = true
}

variable "kms_alias_name" {
  type        = string
  sensitive   = true
}

variable "kms_key_admin_arn" {
  type        = string
  sensitive   = true
}

variable "kms_key_user_arn" {
  type        = string
  sensitive   = true
}