provider "aws" {
  region = var.aws_region
}

resource "aws_secretsmanager_secret" "example" {
  name = var.secret_name
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode(var.secret_value)
}

resource "aws_secretsmanager_secret_rotation" "example" {
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
}

resource "aws_iam_role" "example" {
  name        = var.lambda_execution_role_name
  description = "Execution role for lambda"

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
}

resource "aws_iam_policy" "example" {
  name        = var.lambda_execution_policy_name
  description = "Policy for lambda execution"

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
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "secret_name" {
  type        = string
  description = "Secret Name"
}

variable "secret_value" {
  type        = map(string)
  description = "Secret Value"
}

variable "lambda_function_name" {
  type        = string
  description = "Lambda Function Name"
}

variable "lambda_execution_role_name" {
  type        = string
  description = "Lambda Execution Role Name"
}

variable "lambda_execution_policy_name" {
  type        = string
  description = "Lambda Execution Policy Name"
}