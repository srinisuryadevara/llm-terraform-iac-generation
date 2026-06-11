terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

resource "aws_sns_topic" "topic" {
  name = var.topic_name
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = var.email_endpoint
}

variable "region" {
  type        = string
  sensitive   = true
  description = "AWS region"
}

variable "topic_name" {
  type        = string
  sensitive   = false
  description = "SNS topic name"
}

variable "email_endpoint" {
  type        = string
  sensitive   = true
  description = "Email endpoint for SNS subscription"
}