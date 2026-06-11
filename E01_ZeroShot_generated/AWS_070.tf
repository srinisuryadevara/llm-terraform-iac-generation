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
  name        = var.lambda_iam_role_name
  description = "Execution role for lambda function"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid      = ""
      }
    ]
  })
}

resource "aws_iam_policy" "example" {
  name        = var.lambda_iam_policy_name
  description = "Policy for lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:*"
        Effect    = "Allow"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
        ]
        Resource = aws_secretsmanager_secret.example.arn
        Effect    = "Allow"
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

variable "lambda_iam_role_name" {
  type        = string
  sensitive   = true
}

variable "lambda_iam_policy_name" {
  type        = string
  sensitive   = true
}