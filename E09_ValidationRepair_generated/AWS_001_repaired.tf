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
  description = "Lambda Execution Role Name"
}

variable "log_group_name" {
  type        = string
  description = "CloudWatch Log Group Name"
}

resource "aws_iam_role" "lambda_execution_role" {
  name        = var.lambda_role_name
  description = "Execution role for Lambda function"

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
    Name        = var.lambda_role_name
    Environment = "production"
  }
}

resource "aws_iam_policy" "lambda_execution_policy" {
  name        = "${var.lambda_role_name}-policy"
  description = "Policy for Lambda execution role"

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
      }
    ]
  })

  tags = {
    Name        = "${var.lambda_role_name}-policy"
    Environment = "production"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = var.log_group_name
  retention_in_days = 30

  tags = {
    Name        = var.log_group_name
    Environment = "production"
  }
}

resource "aws_lambda_function" "lambda_function" {
  filename      = "lambda_function_payload.zip"
  function_name = var.lambda_function_name
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_execution_role.arn

  tags = {
    Name        = var.lambda_function_name
    Environment = "production"
  }
}

output "lambda_function_arn" {
  value       = aws_lambda_function.lambda_function.arn
  description = "ARN of the Lambda function"
}

output "lambda_function_name" {
  value       = aws_lambda_function.lambda_function.function_name
  description = "Name of the Lambda function"
}

output "lambda_log_group_name" {
  value       = aws_cloudwatch_log_group.lambda_log_group.name
  description = "Name of the CloudWatch log group"
}

output "lambda_execution_role_arn" {
  value       = aws_iam_role.lambda_execution_role.arn
  description = "ARN of the Lambda execution role"
}

output "lambda_execution_role_name" {
  value       = aws_iam_role.lambda_execution_role.name
  description = "Name of the Lambda execution role"
}