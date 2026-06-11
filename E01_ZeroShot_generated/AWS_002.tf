provider "aws" {
  region = var.aws_region
}

resource "aws_kms_key" "this" {
  description             = var.kms_key_description
  deletion_window_in_days = var.deletion_window_in_days
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.kms_key_alias}"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_kms_key_policy" "this" {
  key_id = aws_kms_key.this.key_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = {
          AWS = var.iam_arn
        }
        Action = "kms:*"
        Resource = "*"
      },
      {
        Sid       = "Allow access for Key Administrators"
        Effect    = "Allow"
        Principal = {
          AWS = var.key_admin_arn
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
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
  sensitive   = false
}

variable "deletion_window_in_days" {
  type        = number
  sensitive   = false
}

variable "kms_key_alias" {
  type        = string
  sensitive   = false
}

variable "iam_arn" {
  type        = string
  sensitive   = true
}

variable "key_admin_arn" {
  type        = string
  sensitive   = true
}