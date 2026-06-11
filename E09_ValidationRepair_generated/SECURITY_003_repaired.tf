provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "bucket_name" {
  type        = string
  description = "S3 Bucket Name"
}

variable "lambda_function_name" {
  type        = string
  description = "Lambda Function Name"
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*",
    ]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.lambda_function_name}-policy"
  description = "Least-privilege policy for Lambda function"
  policy      = data.aws_iam_policy_document.lambda_policy.json
  tags = {
    Name        = "${var.lambda_function_name}-policy"
    Environment = "production"
  }
}

resource "aws_iam_role" "lambda_role" {
  name        = "${var.lambda_function_name}-role"
  description = "Role for Lambda function"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
  tags = {
    Name        = "${var.lambda_function_name}-role"
    Environment = "production"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "lambda_function" {
  filename      = "lambda_function_payload.zip"
  function_name = var.lambda_function_name
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  role          = aws_iam_role.lambda_role.arn
  tags = {
    Name        = var.lambda_function_name
    Environment = "production"
  }
}

output "lambda_function_arn" {
  value       = aws_lambda_function.lambda_function.arn
  description = "ARN of the Lambda function"
}

output "lambda_function_name" {
  value       = aws_lambda_function.lambda_function.function_name
  description = "Name of the Lambda function"
}

output "lambda_policy_arn" {
  value       = aws_iam_policy.lambda_policy.arn
  description = "ARN of the Lambda policy"
}

output "lambda_role_arn" {
  value       = aws_iam_role.lambda_role.arn
  description = "ARN of the Lambda role"
}