provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  name         = basename(path.cwd)
  secret_name  = "example-secret"
  rotation_lambda_name = "example-rotation-lambda"
  rotation_schedule = "rate(1 day)"
}

variable "rotation_lambda_iam_policy" {
  type = string
}

variable "rotation_lambda_iam_role" {
  type = string
}

variable "region" {
  type = string
}

variable "rotation_lambda_function_name" {
  type = string
}

resource "aws_secretsmanager_secret" "example" {
  name = local.secret_name
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({
    username = "example-username",
    password = "example-password"
  })
}

resource "aws_secretsmanager_secret_policy" "example" {
  secret_arn = aws_secretsmanager_secret.example.arn
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = "secretsmanager:GetSecretValue"
        Resource = "*"
      },
    ]
  })
}

resource "aws_lambda_function" "rotation" {
  filename      = "lambda_function_payload.zip"
  function_name = local.rotation_lambda_name
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  role          = var.rotation_lambda_iam_role
}

resource "aws_lambda_permission" "rotation" {
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = aws_secretsmanager_secret.example.arn
}

resource "aws_secretsmanager_secret_rotation" "example" {
  secret_id           = aws_secretsmanager_secret.example.id
  rotation_lambda_arn = aws_lambda_function.rotation.arn
  rotation_rules {
    automatically_after_days = 1
  }
}

resource "aws_cloudwatch_event_rule" "rotation" {
  name                = "example-rotation-rule"
  schedule_expression = local.rotation_schedule
}

resource "aws_cloudwatch_event_target" "rotation" {
  rule      = aws_cloudwatch_event_rule.rotation.name
  target_id = "SecretsManagerRotation"
  arn       = aws_secretsmanager_secret.example.arn
}

resource "aws_cloudwatch_event_permission" "rotation" {
  principal   = "events.amazonaws.com"
  statement_id = "AllowExecutionFromCloudWatch"
  action       = "secretsmanager:RotateSecret"
  source_arn   = aws_cloudwatch_event_rule.rotation.arn
}