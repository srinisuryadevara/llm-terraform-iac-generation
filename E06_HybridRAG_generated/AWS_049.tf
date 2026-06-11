terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.14.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_secretsmanager_secret" "example" {
  name = var.secret_name
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = var.secret_value
}

resource "aws_secretsmanager_rotation" "example" {
  secret_id           = aws_secretsmanager_secret.example.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_period
  }
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "secret_name" {
  type        = string
  description = "Name of the secret"
}

variable "secret_value" {
  type        = string
  description = "Value of the secret"
  sensitive   = true
}

variable "rotation_lambda_arn" {
  type        = string
  description = "ARN of the rotation lambda function"
}

variable "rotation_period" {
  type        = number
  description = "Rotation period in days"
}