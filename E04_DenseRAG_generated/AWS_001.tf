terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "lambda_function_name" {
  type        = string
  sensitive   = true
}

variable "lambda_handler" {
  type        = string
  sensitive   = true
}

variable "lambda_runtime" {
  type        = string
  sensitive   = true
}

variable "lambda_filename" {
  type        = string
  sensitive   = true
}

variable "lambda_source_code_hash" {
  type        = string
  sensitive   = true
}

variable "lambda_timeout" {
  type        = number
  sensitive   = true
}

variable "lambda_memory_size" {
  type        = number
  sensitive   = true
}

variable "lambda_environment_variables" {
  type        = map(string)
  sensitive   = true
}

resource "aws_iam_role" "lambda_exec" {
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
        Sid      = ""
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
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

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "example" {
  filename      = var.lambda_filename
  function_name = var.lambda_function_name
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout
  source_code_hash = var.lambda_source_code_hash

  environment {
    variables = var.lambda_environment_variables
  }
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/${aws_lambda_function.example.function_name}"
  retention_in_days = 14
}