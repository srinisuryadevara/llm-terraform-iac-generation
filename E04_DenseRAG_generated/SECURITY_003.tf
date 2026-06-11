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
  region = var.region
}

resource "aws_iam_policy" "lambda_s3_read_policy" {
  name        = "lambda-s3-read-policy"
  description = "Least-privilege IAM policy for AWS Lambda with S3 read permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Effect = "Allow"
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*",
        ]
      },
    ]
  })
}

resource "aws_iam_role" "lambda_exec" {
  name        = "lambda-exec-role"
  description = "IAM role for AWS Lambda execution"

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
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_read_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_read_policy.arn
}

resource "aws_lambda_function" "example" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda_exec.arn
  filename         = var.function_filename
  handler          = var.function_handler
  runtime          = var.function_runtime
  source_code_hash = filebase64sha256(var.function_filename)
  timeout          = var.function_timeout

  environment {
    variables = {
      BUCKET_NAME = var.s3_bucket_name
    }
  }
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "s3_bucket_arn" {
  type        = string
  description = "S3 bucket ARN"
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket name"
}

variable "function_name" {
  type        = string
  description = "Lambda function name"
}

variable "function_filename" {
  type        = string
  description = "Lambda function filename"
}

variable "function_handler" {
  type        = string
  description = "Lambda function handler"
}

variable "function_runtime" {
  type        = string
  description = "Lambda function runtime"
}

variable "function_timeout" {
  type        = number
  description = "Lambda function timeout"
}