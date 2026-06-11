provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "lambda_function_name" {
  type        = string
  description = "Lambda Function Name"
}

variable "lambda_handler" {
  type        = string
  description = "Lambda Handler"
}

variable "lambda_runtime" {
  type        = string
  description = "Lambda Runtime"
}

variable "lambda_role_name" {
  type        = string
  description = "Lambda IAM Role Name"
}

resource "aws_iam_role" "lambda_exec" {
  name        = var.lambda_role_name
  description = "Execution role for Lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })

  tags = {
    Name        = var.lambda_role_name
    Environment = "production"
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-policy"
  description = "Policy for Lambda"

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
      }
    ]
  })

  tags = {
    Name        = "lambda-policy"
    Environment = "production"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "example" {
  filename      = "lambda_function_payload.zip"
  function_name = var.lambda_function_name
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn

  tags = {
    Name        = var.lambda_function_name
    Environment = "production"
  }
}

output "lambda_function_arn" {
  value       = aws_lambda_function.example.arn
  description = "The ARN of the Lambda function"
}

output "lambda_function_name" {
  value       = aws_lambda_function.example.function_name
  description = "The name of the Lambda function"
}

output "lambda_iam_role_arn" {
  value       = aws_iam_role.lambda_exec.arn
  description = "The ARN of the IAM role for Lambda"
}

output "lambda_iam_policy_arn" {
  value       = aws_iam_policy.lambda_policy.arn
  description = "The ARN of the IAM policy for Lambda"
}