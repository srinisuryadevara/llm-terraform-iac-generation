provider "aws" {
  region = var.aws_region
}

resource "aws_secretsmanager_secret" "example" {
  name        = var.secret_name
  description = "Example secret for rotation policy"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode(var.secret_value)
}

resource "aws_secretsmanager_rotation" "example" {
  secret_id           = aws_secretsmanager_secret.example.id
  rotation_lambda_arn = aws_lambda_function.example.arn

  rotation_rules {
    automatically_after_days = 30
  }
}

resource "aws_lambda_function" "example" {
  filename      = "lambda_function_payload.zip"
  function_name = var.lambda_function_name
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  role          = aws_iam_role.example.arn

  tags = {
    Name        = var.lambda_function_name
    Environment = "example"
  }
}

resource "aws_iam_role" "example" {
  name        = var.iam_role_name
  description = "Execution role for Secrets Manager rotation lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name        = var.iam_role_name
    Environment = "example"
  }
}

resource "aws_iam_policy" "example" {
  name        = var.iam_policy_name
  description = "Policy for Secrets Manager rotation lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
        ]
        Effect = "Allow"
        Resource = aws_secretsmanager_secret.example.arn
      },
      {
        Action = "logs:CreateLogGroup"
        Effect = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = "logs:CreateLogStream"
        Effect = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = "logs:PutLogEvents"
        Effect = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })

  tags = {
    Name        = var.iam_policy_name
    Environment = "example"
  }
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}

resource "aws_secretsmanager_secret" "example_tags" {
  name        = var.secret_name
  description = "Example secret for rotation policy"

  tags = {
    Name        = var.secret_name
    Environment = "example"
  }
}

output "secret_id" {
  value       = aws_secretsmanager_secret.example.id
  description = "The ID of the Secrets Manager secret"
}

output "secret_arn" {
  value       = aws_secretsmanager_secret.example.arn
  description = "The ARN of the Secrets Manager secret"
}

output "lambda_function_name" {
  value       = aws_lambda_function.example.function_name
  description = "The name of the Lambda function"
}

output "lambda_function_arn" {
  value       = aws_lambda_function.example.arn
  description = "The ARN of the Lambda function"
}

output "iam_role_name" {
  value       = aws_iam_role.example.name
  description = "The name of the IAM role"
}

output "iam_role_arn" {
  value       = aws_iam_role.example.arn
  description = "The ARN of the IAM role"
}

output "iam_policy_name" {
  value       = aws_iam_policy.example.name
  description = "The name of the IAM policy"
}

output "iam_policy_arn" {
  value       = aws_iam_policy.example.arn
  description = "The ARN of the IAM policy"
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "secret_name" {
  type        = string
  sensitive   = true
}

variable "secret_value" {
  type        = map(string)
  sensitive   = true
}

variable "lambda_function_name" {
  type        = string
  sensitive   = true
}

variable "iam_role_name" {
  type        = string
  sensitive   = true
}

variable "iam_policy_name" {
  type        = string
  sensitive   = true
}