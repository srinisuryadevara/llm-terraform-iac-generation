provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "project_name" {
  type        = string
  description = "Project Name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "topic_name" {
  type        = string
  description = "SNS Topic Name"
}

variable "email_address" {
  type        = string
  description = "Email Address for SNS Subscription"
}

resource "aws_sns_topic" "this" {
  name = var.topic_name

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.email_address
}

resource "aws_iam_policy" "this" {
  name        = "${var.project_name}-${var.environment}-sns-policy"
  description = "Policy for SNS Topic"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSNSPublish"
        Effect    = "Allow"
        Action    = "sns:Publish"
        Resource = aws_sns_topic.this.arn
      },
    ]
  })
}

resource "aws_iam_role" "this" {
  name        = "${var.project_name}-${var.environment}-sns-role"
  description = "Role for SNS Topic"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}