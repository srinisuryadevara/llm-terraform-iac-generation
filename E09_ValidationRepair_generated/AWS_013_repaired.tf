provider "aws" {
  region = var.aws_region
}

resource "aws_secretsmanager_secret" "example" {
  name        = var.secret_name
  description = "AWS Secrets Manager secret"
  tags = {
    Name        = var.secret_name
    Environment = "example"
  }
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode(var.secret_value)
}

resource "aws_secretsmanager_secret_policy" "example" {
  secret_arn = aws_secretsmanager_secret.example.arn
  policy      = jsonencode(var.secret_policy)
}

resource "aws_secretsmanager_rotation" "example" {
  secret_id           = aws_secretsmanager_secret.example.id
  rotation_lambda_arn = aws_lambda_function.example.arn
  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}

resource "aws_lambda_function" "example" {
  filename      = var.lambda_filename
  function_name = var.lambda_function_name
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.example.arn
  tags = {
    Name        = var.lambda_function_name
    Environment = "example"
  }
}

resource "aws_iam_role" "example" {
  name        = var.lambda_iam_role_name
  description = var.lambda_iam_role_description

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
    Name        = var.lambda_iam_role_name
    Environment = "example"
  }
}

resource "aws_iam_policy" "example" {
  name        = var.lambda_iam_policy_name
  description = var.lambda_iam_policy_description

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
    Name        = var.lambda_iam_policy_name
    Environment = "example"
  }
}

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "secret_name" {
  type        = string
  description = "Secret name"
}

variable "secret_value" {
  type        = map(string)
  description = "Secret value"
}

variable "secret_policy" {
  type        = string
  description = "Secret policy"
}

variable "rotation_days" {
  type        = number
  description = "Rotation days"
}

variable "lambda_filename" {
  type        = string
  description = "Lambda filename"
}

variable "lambda_function_name" {
  type        = string
  description = "Lambda function name"
}

variable "lambda_handler" {
  type        = string
  description = "Lambda handler"
}

variable "lambda_runtime" {
  type        = string
  description = "Lambda runtime"
}

variable "lambda_iam_role_name" {
  type        = string
  description = "Lambda IAM role name"
}

variable "lambda_iam_role_description" {
  type        = string
  description = "Lambda IAM role description"
}

variable "lambda_iam_policy_name" {
  type        = string
  description = "Lambda IAM policy name"
}

variable "lambda_iam_policy_description" {
  type        = string
  description = "Lambda IAM policy description"
}

output "secret_id" {
  value       = aws_secretsmanager_secret.example.id
  description = "Secret ID"
}

output "secret_arn" {
  value       = aws_secretsmanager_secret.example.arn
  description = "Secret ARN"
}

output "lambda_function_name" {
  value       = aws_lambda_function.example.function_name
  description = "Lambda function name"
}

output "lambda_function_arn" {
  value       = aws_lambda_function.example.arn
  description = "Lambda function ARN"
}

output "iam_role_name" {
  value       = aws_iam_role.example.name
  description = "IAM role name"
}

output "iam_role_arn" {
  value       = aws_iam_role.example.arn
  description = "IAM role ARN"
}