provider "aws" {
  region = var.region
}

resource "aws_kms_key" "this" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
}

resource "aws_kms_alias" "this" {
  name          = var.alias_name
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
          AWS = var.principal_arn
        }
        Action = "kms:*"
        Resource = "*"
      },
    ]
  })
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "description" {
  type        = string
  description = "KMS key description"
}

variable "deletion_window_in_days" {
  type        = number
  description = "KMS key deletion window in days"
}

variable "alias_name" {
  type        = string
  description = "KMS key alias name"
}

variable "principal_arn" {
  type        = string
  description = "KMS key policy principal ARN"
}