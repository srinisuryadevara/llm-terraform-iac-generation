provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name"
}

variable "function_name" {
  type        = string
  description = "Lambda function name"
}

variable "function_handler" {
  type        = string
  description = "Lambda function handler"
}

variable "function_runtime" {
  type        = string
  description = "Lambda function runtime"
}

variable "function_filename" {
  type        = string
  description = "Lambda function filename"
}

resource "aws_iam_role" "lambda_exec" {
  name        = "${var.function_name}-lambda-exec"
  description = "Execution role for ${var.function_name} Lambda function"

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

resource "aws_iam_policy" "lambda_exec_policy" {
  name        = "${var.function_name}-lambda-exec-policy"
  description = "Execution policy for ${var.function_name} Lambda function"

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
      },
      {
        Action = [
          "s3:GetObject",
        ]
        Effect = "Allow"
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_exec_policy.arn
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
}

resource "aws_lambda_function" "lambda_function" {
  filename      = var.function_filename
  function_name = var.function_name
  handler       = var.function_handler
  runtime       = var.function_runtime
  role          = aws_iam_role.lambda_exec.arn
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.bucket_name}"
}