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
  description = "AWS region"
}

variable "lambda_function_name" {
  type        = string
  sensitive   = false
  description = "Lambda function name"
}

variable "lambda_handler" {
  type        = string
  sensitive   = false
  description = "Lambda function handler"
}

variable "lambda_runtime" {
  type        = string
  sensitive   = false
  description = "Lambda function runtime"
}

variable "lambda_s3_bucket" {
  type        = string
  sensitive   = false
  description = "Lambda function S3 bucket"
}

variable "lambda_s3_key" {
  type        = string
  sensitive   = false
  description = "Lambda function S3 key"
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-execution-role"

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

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda-execution-policy"
  description = "IAM policy for Lambda function execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_exec.name
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/${var.lambda_function_name}"
}

resource "aws_lambda_function" "example" {
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  s3_bucket        = var.lambda_s3_bucket
  s3_key           = var.lambda_s3_key
  source_code_hash = filebase64sha256("${var.lambda_s3_bucket}/${var.lambda_s3_key}")
}