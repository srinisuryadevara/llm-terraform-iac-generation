variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "iam_role_name" {
  type        = string
  description = "IAM Role Name"
}

variable "iam_policy_name" {
  type        = string
  description = "IAM Policy Name"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "s3_read_access" {
  name        = var.iam_role_name
  description = "Least-privilege IAM role for S3 read access"

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

  tags = {
    Name        = var.iam_role_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_policy" "s3_read_access" {
  name        = var.iam_policy_name
  description = "Least-privilege IAM policy for S3 read access"

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

  tags = {
    Name        = var.iam_policy_name
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "s3_read_access" {
  role       = aws_iam_role.s3_read_access.name
  policy_arn = aws_iam_policy.s3_read_access.arn

  tags = {
    Name        = "s3-read-access-attachment"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

output "iam_role_arn" {
  value       = aws_iam_role.s3_read_access.arn
  description = "The ARN of the IAM role"
}

output "iam_role_id" {
  value       = aws_iam_role.s3_read_access.id
  description = "The ID of the IAM role"
}

output "iam_policy_arn" {
  value       = aws_iam_policy.s3_read_access.arn
  description = "The ARN of the IAM policy"
}

output "iam_policy_id" {
  value       = aws_iam_policy.s3_read_access.id
  description = "The ID of the IAM policy"
}