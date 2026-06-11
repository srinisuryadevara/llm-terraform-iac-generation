provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "function_name" {
  type        = string
  description = "AWS Lambda Function Name"
}

variable "s3_bucket" {
  type        = string
  description = "AWS S3 Bucket Name"
}

variable "s3_key" {
  type        = string
  description = "AWS S3 Key"
}

variable "handler" {
  type        = string
  description = "AWS Lambda Handler"
}

variable "runtime" {
  type        = string
  description = "AWS Lambda Runtime"
}

resource "aws_iam_role" "lambda_exec" {
  name        = "serverless_example_lambda"
  description = "Execution role for AWS Lambda"

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

resource "aws_lambda_function" "example" {
  function_name = var.function_name

  s3_bucket = var.s3_bucket
  s3_key    = var.s3_key

  handler = var.handler
  runtime = var.runtime

  role = aws_iam_role.lambda_exec.arn
}