provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "project" {
  type        = string
  description = "Project"
}

resource "aws_iam_role" "s3_read_role" {
  name        = "s3-read-role-${var.environment}-${var.project}"
  description = "Least-privilege IAM role for S3 read access"

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

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_policy" "s3_read_policy" {
  name        = "s3-read-policy-${var.environment}-${var.project}"
  description = "Least-privilege IAM policy for S3 read access"

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
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*",
        ]
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 Bucket Name"
}

resource "aws_iam_role_policy_attachment" "s3_read_attach" {
  role       = aws_iam_role.s3_read_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}