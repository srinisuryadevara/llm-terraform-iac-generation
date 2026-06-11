provider "aws" {
  region = var.aws_region
}

resource "aws_kms_key" "example" {
  description             = var.kms_key_description
  deletion_window_in_days = var.deletion_window_in_days
  tags = {
    Name        = var.kms_key_alias
    Environment = "example"
  }
}

resource "aws_kms_alias" "example" {
  name          = "alias/${var.kms_key_alias}"
  target_key_id = aws_kms_key.example.key_id
  tags = {
    Name        = var.kms_key_alias
    Environment = "example"
  }
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
  description = "AWS Region"
}

variable "kms_key_description" {
  type        = string
  description = "KMS Key Description"
}

variable "deletion_window_in_days" {
  type        = number
  description = "Deletion Window in Days"
}

variable "kms_key_alias" {
  type        = string
  description = "KMS Key Alias"
}

variable "kms_key_admin_arn" {
  type        = string
  description = "KMS Key Admin ARN"
}

variable "kms_key_user_arn" {
  type        = string
  description = "KMS Key User ARN"
}

output "kms_key_id" {
  value       = aws_kms_key.example.key_id
  description = "KMS Key ID"
}

output "kms_key_arn" {
  value       = aws_kms_key.example.arn
  description = "KMS Key ARN"
}

output "kms_alias_name" {
  value       = aws_kms_alias.example.name
  description = "KMS Alias Name"
}