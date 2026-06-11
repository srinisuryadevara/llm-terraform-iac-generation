provider "aws" {
  region = var.region
}

resource "aws_iam_role" "lambda_exec" {
  name = var.lambda_function_name

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
  name        = "${var.lambda_function_name}-lambda-execution-policy"
  description = "IAM policy for Lambda execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
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

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/${var.lambda_function_name}"
}

resource "aws_lambda_function" "example" {
  filename      = var.lambda_function_filename
  function_name = var.lambda_function_name
  handler       = var.lambda_function_handler
  runtime       = var.lambda_function_runtime
  role          = aws_iam_role.lambda_exec.arn
}

variable "region" {
  type        = string
  default     = "us-east-1"
}

variable "lambda_function_name" {
  type        = string
  default     = "ServerlessExample"
}

variable "lambda_function_filename" {
  type        = string
  default     = "lambda_function_payload.zip"
}

variable "lambda_function_handler" {
  type        = string
  default     = "main.handler"
}

variable "lambda_function_runtime" {
  type        = string
  default     = "nodejs10.x"
}