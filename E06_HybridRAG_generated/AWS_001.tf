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

module "aws_iam_lambda_execution_role" {
  source = "../terraform_modules/aws_iam_lambda_execution_role"

  role_name = var.lambda_execution_role_name
}

resource "aws_lambda_function" "example" {
  function_name = var.lambda_function_name

  filename         = var.lambda_function_filename
  handler          = var.lambda_function_handler
  runtime          = var.lambda_function_runtime
  role             = module.aws_iam_lambda_execution_role.role_arn
  source_code_hash = filebase64sha256(var.lambda_function_filename)

  environment {
    variables = {
      TEST_ENV_VARIABLE_ONE = var.test_env_variable_one,
      TEST_ENV_VARIABLE_TWO = var.test_env_variable_two,
    }
  }
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/${aws_lambda_function.example.function_name}"
  retention_in_days = var.log_retention_in_days
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "lambda_execution_role_name" {
  type        = string
  description = "Lambda execution role name"
}

variable "lambda_function_name" {
  type        = string
  description = "Lambda function name"
}

variable "lambda_function_filename" {
  type        = string
  description = "Lambda function filename"
}

variable "lambda_function_handler" {
  type        = string
  description = "Lambda function handler"
}

variable "lambda_function_runtime" {
  type        = string
  description = "Lambda function runtime"
}

variable "test_env_variable_one" {
  type        = string
  description = "Test environment variable one"
  sensitive   = true
}

variable "test_env_variable_two" {
  type        = string
  description = "Test environment variable two"
  sensitive   = true
}

variable "log_retention_in_days" {
  type        = number
  description = "Log retention in days"
}