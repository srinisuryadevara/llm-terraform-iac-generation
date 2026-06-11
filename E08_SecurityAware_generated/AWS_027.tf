provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project Name"
}

variable "environment" {
  type        = string
  description = "Environment"
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

variable "lambda_role_arn" {
  type        = string
  description = "Lambda Execution Role ARN"
}

resource "aws_iam_role" "lambda_execution_role" {
  name        = "${var.project}-${var.environment}-lambda-execution-role"
  description = "Lambda Execution Role"

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
    Name        = "${var.project}-${var.environment}-lambda-execution-role"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_policy" "lambda_execution_policy" {
  name        = "${var.project}-${var.environment}-lambda-execution-policy"
  description = "Lambda Execution Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${var.project}-${var.environment}-lambda-log-group"
        Effect    = "Allow"
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.environment}-lambda-execution-policy"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

resource "aws_lambda_function" "lambda_function" {
  filename      = "lambda_function_payload.zip"
  function_name = var.lambda_function_name
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_execution_role.arn

  tags = {
    Name        = var.lambda_function_name
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "${var.project}-${var.environment}-lambda-log-group"
  retention_in_days = 30

  tags = {
    Name        = "${var.project}-${var.environment}-lambda-log-group"
    Environment = var.environment
    Project     = var.project
  }
}

data "aws_caller_identity" "current" {
  provider = aws
}