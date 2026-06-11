variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "role_name" {
  type        = string
  description = "IAM Role Name"
}

variable "policy_name" {
  type        = string
  description = "IAM Policy Name"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "s3_read_access" {
  name        = var.role_name
  description = "Least-privilege role for S3 read access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.aws_account_id
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_read_access" {
  name        = var.policy_name
  description = "Least-privilege policy for S3 read access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::example-bucket",
          "arn:aws:s3:::example-bucket/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read_access" {
  role       = aws_iam_role.s3_read_access.name
  policy_arn = aws_iam_policy.s3_read_access.arn
}