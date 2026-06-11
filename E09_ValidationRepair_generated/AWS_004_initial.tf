provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "iam_role_name" {
  type        = string
  description = "IAM Role Name"
}

variable "iam_policy_name" {
  type        = string
  description = "IAM Policy Name"
}

resource "aws_iam_role" "s3_read_access" {
  name        = var.iam_role_name
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

resource "aws_iam_policy" "s3_read_access" {
  name        = var.iam_policy_name
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

output "iam_role_arn" {
  value       = aws_iam_role.s3_read_access.arn
  description = "ARN of the IAM Role"
}

output "iam_policy_arn" {
  value       = aws_iam_policy.s3_read_access.arn
  description = "ARN of the IAM Policy"
}