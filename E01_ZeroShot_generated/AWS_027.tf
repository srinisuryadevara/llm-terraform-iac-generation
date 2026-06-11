provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "lambda_function_name" {
  type        = string
  sensitive   = false
  default     = "example-lambda-function"
}

variable "lambda_function_runtime" {
  type        = string
  sensitive   = false
  default     = "nodejs14.x"
}

variable "lambda_function_handler" {
  type        = string
  sensitive   = false
  default     = "index.handler"
}

variable "lambda_function_role_arn" {
  type        = string
  sensitive   = true
}

variable "cloudwatch_log_group_name" {
  type        = string
  sensitive   = false
  default     = "/aws/lambda/example-lambda-function"
}

resource "aws_iam_role" "lambda_execution_role" {
  name        = "lambda-execution-role"
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
}

resource "aws_iam_policy" "lambda_execution_policy" {
  name        = "lambda-execution-policy"
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
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

resource "aws_lambda_function" "example_lambda_function" {
  filename      = "lambda_function_payload.zip"
  function_name = var.lambda_function_name
  handler       = var.lambda_function_handler
  runtime       = var.lambda_function_runtime
  role          = aws_iam_role.lambda_execution_role.arn
}

resource "aws_cloudwatch_log_group" "example_log_group" {
  name              = var.cloudwatch_log_group_name
  retention_in_days = 14
}