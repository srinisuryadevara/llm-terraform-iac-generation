provider "aws" {
  region = var.aws_region
}

resource "aws_kms_key" "example" {
  description             = var.kms_key_description
  deletion_window_in_days = var.deletion_window_in_days
  tags = {
    Name        = "example-kms-key"
    Environment = "example"
  }
}

resource "aws_kms_alias" "example" {
  name          = var.kms_alias_name
  target_key_id = aws_kms_key.example.key_id
  tags = {
    Name        = "example-kms-alias"
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

output "kms_key_id" {
  value       = aws_kms_key.example.key_id
  description = "The ID of the KMS key"
}

output "kms_key_arn" {
  value       = aws_kms_key.example.arn
  description = "The ARN of the KMS key"
}

output "kms_alias_name" {
  value       = aws_kms_alias.example.name
  description = "The name of the KMS alias"
}

output "kms_key_policy_id" {
  value       = aws_kms_key_policy.example.id
  description = "The ID of the KMS key policy"
}