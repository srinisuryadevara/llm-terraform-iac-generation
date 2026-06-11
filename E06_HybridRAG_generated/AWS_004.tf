variable "role_name" {
  type        = string
  description = "Name of the IAM role"
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
}

data "aws_caller_identity" "current" {}

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
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_read_access" {
  name        = "s3-read-access-policy"
  description = "Policy for S3 read access"

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
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read_access" {
  role       = aws_iam_role.s3_read_access.name
  policy_arn = aws_iam_policy.s3_read_access.arn
}