provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "project" {
  type        = string
  description = "Project Name"
}

variable "secret_name" {
  type        = string
  description = "Secret Name"
}

variable "rotation_lambda_arn" {
  type        = string
  description = "Rotation Lambda ARN"
}

resource "aws_secretsmanager_secret" "example" {
  name        = var.secret_name
  description = "Example Secret"
  tags = {
    Project     = var.project
    Environment = "example"
  }
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({
    username = "example",
    password = "example",
  })
}

resource "aws_secretsmanager_secret_rotation" "example" {
  secret_id           = aws_secretsmanager_secret.example.id
  rotation_lambda_arn = var.rotation_lambda_arn
  rotation_rules {
    automatically_after_days = 30
  }
}

resource "aws_iam_policy" "rotation" {
  name        = "secret-rotation-policy"
  description = "Policy for secret rotation"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
        ]
        Resource = aws_secretsmanager_secret.example.arn
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
        ]
        Resource = var.rotation_lambda_arn
      },
    ]
  })
}

resource "aws_iam_role" "rotation" {
  name        = "secret-rotation-role"
  description = "Role for secret rotation"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rotation" {
  role       = aws_iam_role.rotation.name
  policy_arn = aws_iam_policy.rotation.arn
}