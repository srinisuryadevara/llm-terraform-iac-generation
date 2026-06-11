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

resource "aws_iam_role" "lambda_exec" {
  name = var.lambda_exec_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_exec_policy" {
  name        = var.lambda_exec_policy_name
  description = "Policy for Lambda execution"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_exec_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_exec_policy.arn
}

resource "aws_lambda_function" "example" {
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_exec.arn
  description      = var.lambda_function_description
  filename         = var.lambda_function_filename
  handler          = var.lambda_function_handler
  runtime          = var.lambda_function_runtime
  source_code_hash = filebase64sha256(var.lambda_function_filename)
  timeout          = var.lambda_function_timeout

  environment {
    variables = {
      TEST_ENV_VARIABLE_ONE = var.TEST_ENV_VARIABLE_ONE,
      TEST_ENV_VARIABLE_TWO = var.TEST_ENV_VARIABLE_TWO,
    }
  }
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/${aws_lambda_function.example.function_name}"
  retention_in_days = var.log_group_retention_in_days
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
}

variable "lambda_exec_role_name" {
  type        = string
  default     = "lambda_exec_role"
}

variable "lambda_exec_policy_name" {
  type        = string
  default     = "lambda_exec_policy"
}

variable "lambda_function_name" {
  type        = string
  default     = "example_lambda"
}

variable "lambda_function_description" {
  type        = string
  default     = "Example Lambda function"
}

variable "lambda_function_filename" {
  type        = string
  default     = "../lambda/dist/function.zip"
}

variable "lambda_function_handler" {
  type        = string
  default     = "index.handler"
}

variable "lambda_function_runtime" {
  type        = string
  default     = "nodejs16.x"
}

variable "lambda_function_timeout" {
  type        = number
  default     = 10
}

variable "log_group_retention_in_days" {
  type        = number
  default     = 30
}

variable "TEST_ENV_VARIABLE_ONE" {
  type        = string
  sensitive   = true
}

variable "TEST_ENV_VARIABLE_TWO" {
  type        = string
  sensitive   = true
}