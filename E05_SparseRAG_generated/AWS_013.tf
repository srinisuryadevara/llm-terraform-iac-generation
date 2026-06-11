provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  name         = basename(path.cwd)
  secret_name  = "example-secret"
  rotation_lambda_name = "example-rotation-lambda"
  region       = var.region

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

resource "aws_secretsmanager_secret" "this" {
  name = local.secret_name
  description = "Example secret"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    username = "example-username",
    password = "example-password"
  })
}

resource "aws_lambda_function" "this" {
  filename      = "lambda_function_payload.zip"
  function_name = local.rotation_lambda_name
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  role          = aws_iam_role.this.arn
}

resource "aws_iam_role" "this" {
  name        = "example-rotation-lambda-execution-role"
  description = "Execution role for example rotation lambda"

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

resource "aws_iam_policy" "this" {
  name        = "example-rotation-lambda-execution-policy"
  description = "Execution policy for example rotation lambda"

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
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
        ]
        Effect = "Allow"
        Resource = aws_secretsmanager_secret.this.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_secretsmanager_secret_rotation" "this" {
  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = aws_lambda_function.this.arn

  rotation_rules {
    automatically_after_days = 30
  }
}