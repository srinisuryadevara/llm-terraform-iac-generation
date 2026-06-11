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
  default     = "us-east-1"
  description = "AWS region"
}

variable "lambda_function_name" {
  type        = string
  default     = "example-lambda-function"
  description = "Lambda function name"
}

variable "lambda_runtime" {
  type        = string
  default     = "nodejs16.x"
  description = "Lambda runtime"
}

variable "lambda_handler" {
  type        = string
  default     = "index.handler"
  description = "Lambda handler"
}

variable "lambda_filename" {
  type        = string
  default     = "../lambda/dist/function.zip"
  description = "Lambda filename"
}

variable "lambda_memory_size" {
  type        = number
  default     = 128
  description = "Lambda memory size"
}

variable "lambda_timeout" {
  type        = number
  default     = 10
  description = "Lambda timeout"
}

variable "log_group_name" {
  type        = string
  default     = "/aws/lambda/example-lambda-function"
  description = "CloudWatch log group name"
}

variable "log_group_retention_in_days" {
  type        = number
  default     = 30
  description = "CloudWatch log group retention in days"
}

resource "aws_iam_role" "lambda_exec" {
  name        = "example-lambda-execution-role"
  description = "Execution role for example Lambda function"

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
  name        = "example-lambda-policy"
  description = "Policy for example Lambda function"

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

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "example" {
  filename      = var.lambda_filename
  function_name = var.lambda_function_name
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn

  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout
}

resource "aws_cloudwatch_log_group" "example" {
  name              = var.log_group_name
  retention_in_days = var.log_group_retention_in_days
}