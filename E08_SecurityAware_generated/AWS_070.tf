provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "secret_name" {
  type        = string
  description = "Secret name"
}

variable "rotation_lambda_arn" {
  type        = string
  description = "ARN of the Lambda function for secret rotation"
}

resource "aws_secretsmanager_secret" "example" {
  name = var.secret_name
  tags = {
    Project     = var.project
    Environment = "example"
  }
}

resource "aws_secretsmanager_secret_policy" "example" {
  secret_arn = aws_secretsmanager_secret.example.arn
  policy     = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = "secretsmanager:GetSecretValue"
        Resource = "*"
      },
    ]
  })
}

resource "aws_secretsmanager_secret_rotation" "example" {
  secret_id           = aws_secretsmanager_secret.example.id
  rotation_lambda_arn = var.rotation_lambda_arn
  rotation_rules {
    automatically_after_days = 30
  }
}

resource "aws_iam_policy" "rotation_lambda" {
  name        = "rotation-lambda-policy"
  description = "Policy for the Lambda function for secret rotation"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretValue",
        ]
        Resource = aws_secretsmanager_secret.example.arn
      },
      {
        Effect = "Allow"
        Action = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
      },
    ]
  })
}

data "aws_caller_identity" "current" {
  provider = aws
}