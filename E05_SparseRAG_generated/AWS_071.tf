provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "s3_read_access" {
  name        = "s3-read-access"
  description = "Allow read access to S3"

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
  name        = "S3ReadAccessPolicy"
  description = "IAM policy for S3 read access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_read_access" {
  role       = aws_iam_role.s3_read_access.name
  policy_arn = aws_iam_policy.s3_read_access.arn
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "s3_bucket_arn" {
  type        = string
  description = "S3 bucket ARN"
}