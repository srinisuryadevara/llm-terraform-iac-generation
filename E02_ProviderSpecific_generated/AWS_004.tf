provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "role_name" {
  type        = string
  description = "Name of the IAM role"
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
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_read_access_policy" {
  name        = "${var.role_name}-policy"
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
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read_access_attachment" {
  role       = aws_iam_role.s3_read_access.name
  policy_arn = aws_iam_policy.s3_read_access_policy.arn
}

output "role_arn" {
  value       = aws_iam_role.s3_read_access.arn
  description = "ARN of the IAM role"
}

output "role_name" {
  value       = aws_iam_role.s3_read_access.name
  description = "Name of the IAM role"
}