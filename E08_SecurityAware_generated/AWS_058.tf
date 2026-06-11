provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "sns_topic_name" {
  type        = string
  description = "SNS Topic Name"
}

variable "email_subscription_address" {
  type        = string
  description = "Email Subscription Address"
}

variable "environment" {
  type        = string
  description = "Environment"
}

resource "aws_sns_topic" "this" {
  name = var.sns_topic_name

  # Enable server-side encryption
  kms_master_key_id = aws_kms_key.this.arn

  tags = {
    Environment = var.environment
  }
}

resource "aws_kms_key" "this" {
  description             = "KMS Key for SNS Topic"
  deletion_window_in_days = 10

  tags = {
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.email_subscription_address
}

resource "aws_iam_policy" "this" {
  name        = "sns-topic-policy"
  description = "Policy for SNS Topic"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSNSPublish"
        Effect    = "Allow"
        Action    = "sns:Publish"
        Resource = aws_sns_topic.this.arn
        Principal = {
          Service = "sns.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role" "this" {
  name        = "sns-topic-role"
  description = "Role for SNS Topic"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}