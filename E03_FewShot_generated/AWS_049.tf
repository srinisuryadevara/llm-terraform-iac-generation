variable "secret_name" {
  type        = string
  description = "The name of the secret"
}

variable "rotation_lambda_arn" {
  type        = string
  description = "The ARN of the Lambda function for rotation"
}

variable "rotation_period" {
  type        = number
  description = "The rotation period in days"
}

resource "aws_secretsmanager_secret" "example" {
  name = var.secret_name
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({"username": "example", "password": "example"})
}

resource "aws_secretsmanager_secret_rotation" "example" {
  secret_id           = aws_secretsmanager_secret.example.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_period
  }
}