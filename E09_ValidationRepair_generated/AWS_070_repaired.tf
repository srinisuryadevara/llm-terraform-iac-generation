provider "aws" {
  region = var.aws_region
}

resource "aws_secretsmanager_secret" "example" {
  name = var.secret_name
  tags = {
    Name        = var.secret_name
    Environment = "example"
  }
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode(var.secret_string)
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
  name        = var.lambda_execution_role_name
  description = "Execution role for lambda function"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name        = var.lambda_execution_role_name
    Environment = "example"
  }
}

resource "aws_iam_policy" "example" {
  name        = var.lambda_execution_policy_name
  description = "Policy for lambda function execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
        ]
        Effect = "Allow"
        Resource = aws_secretsmanager_secret.example.arn
      },
    ]
  })
  tags = {
    Name        = var.lambda_execution_policy_name
    Environment = "example"
  }
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
  tags = {
    Name        = var.lambda_execution_policy_name
    Environment = "example"
  }
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "secret_name" {
  type        = string
  sensitive   = true
}

variable "secret_string" {
  type        = map(string)
  sensitive   = true
}

variable "lambda_function_name" {
  type        = string
  sensitive   = true
}

variable "lambda_execution_role_name" {
  type        = string
  sensitive   = true
}

variable "lambda_execution_policy_name" {
  type        = string
  sensitive   = true
}

output "secret_id" {
  value       = aws_secretsmanager_secret.example.id
  description = "The ID of the Secrets Manager secret"
}

output "secret_arn" {
  value       = aws_secretsmanager_secret.example.arn
  description = "The ARN of the Secrets Manager secret"
}

output "secret_rotation_lambda_arn" {
  value       = aws_lambda_function.example.arn
  description = "The ARN of the Lambda function used for secret rotation"
}

output "lambda_function_name" {
  value       = aws_lambda_function.example.function_name
  description = "The name of the Lambda function"
}

output "iam_role_name" {
  value       = aws_iam_role.example.name
  description = "The name of the IAM role"
}

output "iam_policy_name" {
  value       = aws_iam_policy.example.name
  description = "The name of the IAM policy"
}