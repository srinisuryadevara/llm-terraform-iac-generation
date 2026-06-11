provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
  description = "AWS Region"
}

variable "secret_name" {
  type        = string
  sensitive   = true
  description = "Secret Name"
}

variable "secret_description" {
  type        = string
  sensitive   = true
  description = "Secret Description"
}

variable "rotation_lambda_arn" {
  type        = string
  sensitive   = true
  description = "Rotation Lambda ARN"
}

variable "rotation_period" {
  type        = number
  sensitive   = true
  description = "Rotation Period"
}

resource "aws_secretsmanager_secret" "example" {
  name                    = var.secret_name
  description             = var.secret_description
  recovery_window_in_days = 30
  tags = {
    Environment = "example"
    Project     = "example"
  }
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({"username" = "example", "password" = "example"})
}

resource "aws_secretsmanager_secret_rotation" "example" {
  secret_id           = aws_secretsmanager_secret.example.id
  rotation_lambda_arn = var.rotation_lambda_arn
  rotation_rules {
    automatically_after_days = var.rotation_period
  }
}

resource "aws_iam_policy" "example" {
  name        = "example"
  description = "example"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:UpdateSecretVersionStage",
        ]
        Resource = aws_secretsmanager_secret.example.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:TagResource",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "example" {
  name        = "example"
  description = "example"
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

resource "aws_iam_role_policy_attachment" "example" {
  role       = aws_iam_role.example.name
  policy_arn = aws_iam_policy.example.arn
}