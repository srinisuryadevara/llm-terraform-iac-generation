provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "lambda_exec" {
  name        = var.lambda_function_name
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
        Effect = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_execution_basic_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_lambda_function" "example" {
  filename      = var.lambda_function_filename
  function_name = var.lambda_function_name
  handler       = var.lambda_function_handler
  runtime       = var.lambda_function_runtime
  role          = aws_iam_role.lambda_exec.arn
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "lambda_function_name" {
  type        = string
  description = "Lambda function name"
}

variable "lambda_function_filename" {
  type        = string
  description = "Lambda function filename"
}

variable "lambda_function_handler" {
  type        = string
  description = "Lambda function handler"
}

variable "lambda_function_runtime" {
  type        = string
  description = "Lambda function runtime"
}

variable "log_retention_in_days" {
  type        = number
  description = "Log retention in days"
}