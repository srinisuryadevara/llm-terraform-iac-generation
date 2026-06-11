provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  name         = basename(path.cwd)
  secret_name  = "example-secret"
  rotation_days = 30

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

resource "aws_secretsmanager_secret" "this" {
  name        = local.secret_name
  description = "Example secret"
  tags        = local.tags
}

resource "aws_secretsmanager_secret_rotation" "this" {
  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = aws_lambda_function.rotation.arn

  rotation_rules {
    automatically_after_days = local.rotation_days
  }
}

resource "aws_lambda_function" "rotation" {
  filename      = "lambda_function_payload.zip"
  function_name = "example-secret-rotation"
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  role          = aws_iam_role.rotation.arn
}

resource "aws_iam_role" "rotation" {
  name        = "example-secret-rotation"
  description = "Example secret rotation role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "rotation" {
  name        = "example-secret-rotation"
  description = "Example secret rotation policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
        ]
        Effect = "Allow"
        Resource = aws_secretsmanager_secret.this.arn
      },
      {
        Action = "logs:CreateLogGroup"
        Effect = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = "logs:CreateLogStream"
        Effect = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = "logs:PutLogEvents"
        Effect = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rotation" {
  role       = aws_iam_role.rotation.name
  policy_arn = aws_iam_policy.rotation.arn
}