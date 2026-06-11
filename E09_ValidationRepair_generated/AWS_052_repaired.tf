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

variable "lambda_function_handler" {
  type        = string
  description = "Lambda Function Handler"
}

variable "lambda_function_runtime" {
  type        = string
  description = "Lambda Function Runtime"
}

variable "lambda_function_filename" {
  type        = string
  description = "Lambda Function Filename"
}

variable "lambda_function_role" {
  type        = string
  description = "Lambda Function IAM Role"
}

resource "aws_iam_role" "lambda_execution_role" {
  name        = var.lambda_function_role
  description = "Execution role for Lambda function"

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
    Name        = var.lambda_function_role
    Environment = "production"
  }
}

resource "aws_iam_policy" "lambda_execution_policy" {
  name        = "${var.lambda_function_name}-execution-policy"
  description = "Policy for Lambda function execution"

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
    Name        = "${var.lambda_function_name}-execution-policy"
    Environment = "production"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14

  tags = {
    Name        = "/aws/lambda/${var.lambda_function_name}"
    Environment = "production"
  }
}

resource "aws_lambda_function" "lambda_function" {
  filename      = var.lambda_function_filename
  function_name = var.lambda_function_name
  handler       = var.lambda_function_handler
  runtime       = var.lambda_function_runtime
  role          = aws_iam_role.lambda_execution_role.arn

  tags = {
    Name        = var.lambda_function_name
    Environment = "production"
  }
}

output "lambda_function_arn" {
  value       = aws_lambda_function.lambda_function.arn
  description = "The ARN of the Lambda function"
}

output "lambda_function_name" {
  value       = aws_lambda_function.lambda_function.function_name
  description = "The name of the Lambda function"
}

output "lambda_log_group_name" {
  value       = aws_cloudwatch_log_group.lambda_log_group.name
  description = "The name of the CloudWatch log group"
}

output "lambda_execution_role_arn" {
  value       = aws_iam_role.lambda_execution_role.arn
  description = "The ARN of the Lambda execution role"
}