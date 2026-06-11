provider "aws" {
  region = var.aws_region
}

resource "aws_kms_key" "this" {
  description             = var.kms_key_description
  deletion_window_in_days = var.kms_key_deletion_window
}

resource "aws_kms_alias" "this" {
  name          = var.kms_key_alias
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
          AWS = var.kms_key_admin_arn
        }
        Action = "kms:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "kms:DescribeKey"
        Resource = "*"
      },
    ]
  })
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "kms_key_description" {
  type        = string
  default     = "AWS KMS Key"
}

variable "kms_key_deletion_window" {
  type        = number
  default     = 30
}

variable "kms_key_alias" {
  type        = string
  default     = "alias/aws/kms-key"
}

variable "kms_key_admin_arn" {
  type        = string
  sensitive   = true
}