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
  description = "Environment Name"
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

variable "lambda_role_description" {
  type        = string
  description = "Lambda Role Description"
}

resource "aws_iam_role" "lambda_exec" {
  name        = "${var.project}-${var.environment}-lambda-exec"
  description = var.lambda_role_description

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
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project}-${var.environment}-lambda-policy"
  description = "Policy for Lambda Execution"

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
    Project     = var.project
    Environment = var.environment
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
    Project     = var.project
    Environment = var.environment
  }
}