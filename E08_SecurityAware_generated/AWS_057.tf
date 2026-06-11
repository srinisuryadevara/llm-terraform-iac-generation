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

  tags = {
    Environment = var.environment
    Name        = var.sns_topic_name
  }
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.email_subscription_address
}

resource "aws_iam_policy" "sns_topic_policy" {
  name        = "${var.sns_topic_name}-policy"
  description = "Policy for SNS Topic"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sns:Publish"
        Resource = aws_sns_topic.this.arn
        Principal = {
          Service = "sns.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Environment = var.environment
    Name        = var.sns_topic_name
  }
}

resource "aws_iam_role" "sns_topic_role" {
  name        = "${var.sns_topic_name}-role"
  description = "Role for SNS Topic"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "sns.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Environment = var.environment
    Name        = var.sns_topic_name
  }
}

resource "aws_iam_role_policy_attachment" "sns_topic_policy_attachment" {
  role       = aws_iam_role.sns_topic_role.name
  policy_arn = aws_iam_policy.sns_topic_policy.arn
}