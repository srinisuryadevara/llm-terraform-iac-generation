provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "account_id" {
  type        = string
  sensitive   = true
}

resource "aws_iam_role" "s3_read_access" {
  name        = "s3-read-access-role"
  description = "Least-privilege role for S3 read access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.account_id
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_read_access_policy" {
  name        = "s3-read-access-policy"
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

resource "aws_iam_role_policy_attachment" "s3_read_access_attachment" {
  role       = aws_iam_role.s3_read_access.name
  policy_arn = aws_iam_policy.s3_read_access_policy.arn
}