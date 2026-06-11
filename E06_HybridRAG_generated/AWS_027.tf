provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "lambda_exec" {
  name = var.lambda_exec_role_name

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

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = var.lambda_log_group_name
}

resource "aws_lambda_function" "example" {
  function_name = var.lambda_function_name

  filename         = var.lambda_filename
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  role             = aws_iam_role.lambda_exec.arn
  source_code_hash = filebase64sha256(var.lambda_filename)

  environment {
    variables = {
      TEST_ENV_VARIABLE_ONE = var.TEST_ENV_VARIABLE_ONE,
      TEST_ENV_VARIABLE_TWO = var.TEST_ENV_VARIABLE_TWO,
    }
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "lambda_exec_role_name" {
  type        = string
  description = "Lambda execution role name"
}

variable "lambda_policy_name" {
  type        = string
  description = "Lambda policy name"
}

variable "lambda_log_group_name" {
  type        = string
  description = "Lambda log group name"
}

variable "lambda_function_name" {
  type        = string
  description = "Lambda function name"
}

variable "lambda_filename" {
  type        = string
  description = "Lambda function filename"
}

variable "lambda_handler" {
  type        = string
  description = "Lambda function handler"
}

variable "lambda_runtime" {
  type        = string
  description = "Lambda function runtime"
}

variable "TEST_ENV_VARIABLE_ONE" {
  type        = string
  description = "Test environment variable one"
}

variable "TEST_ENV_VARIABLE_TWO" {
  type        = string
  description = "Test environment variable two"
}