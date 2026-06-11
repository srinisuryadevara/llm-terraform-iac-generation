provider "aws" {
  region = var.region
}

resource "aws_iam_role" "lambda_exec" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = var.lambda_policy_name
  description = "IAM policy for Lambda function"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Effect   = "Allow",
        Resource = "*",
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_exec.name
}

resource "aws_lambda_function" "example" {
  function_name = var.lambda_function_name

  s3_bucket = var.lambda_s3_bucket
  s3_key    = var.lambda_s3_key

  handler = var.lambda_handler
  runtime = var.lambda_runtime

  role = aws_iam_role.lambda_exec.arn
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "lambda_role_name" {
  type        = string
  default     = "lambda-exec-role"
  description = "Lambda execution role name"
}

variable "lambda_policy_name" {
  type        = string
  default     = "lambda-exec-policy"
  description = "Lambda execution policy name"
}

variable "lambda_function_name" {
  type        = string
  default     = "ServerlessExample"
  description = "Lambda function name"
}

variable "lambda_s3_bucket" {
  type        = string
  description = "S3 bucket for Lambda function code"
}

variable "lambda_s3_key" {
  type        = string
  description = "S3 key for Lambda function code"
}

variable "lambda_handler" {
  type        = string
  default     = "main.handler"
  description = "Lambda function handler"
}

variable "lambda_runtime" {
  type        = string
  default     = "nodejs10.x"
  description = "Lambda function runtime"
}