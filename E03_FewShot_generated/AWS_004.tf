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
  description = "Name of the IAM role"
}

variable "role_description" {
  type        = string
  description = "Description of the IAM role"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "s3_read_access" {
  name        = var.role_name
  description = var.role_description

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
        Sid      = ""
      }
    ]
  })
}

resource "aws_iam_policy" "s3_read_access" {
  name        = "${var.role_name}-policy"
  description = "Policy for S3 read access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::example-bucket",
          "arn:aws:s3:::example-bucket/*",
        ]
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read_access" {
  role       = aws_iam_role.s3_read_access.name
  policy_arn = aws_iam_policy.s3_read_access.arn
}

output "role_arn" {
  value       = aws_iam_role.s3_read_access.arn
  description = "ARN of the IAM role"
}

output "role_name" {
  value       = aws_iam_role.s3_read_access.name
  description = "Name of the IAM role"
}