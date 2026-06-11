provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "sns_topic_name" {
  type        = string
  default     = "example-sns-topic"
}

variable "email_subscription_address" {
  type        = string
  sensitive   = true
}

resource "aws_sns_topic" "example" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "example" {
  topic_arn = aws_sns_topic.example.arn
  protocol  = "email"
  endpoint  = var.email_subscription_address
}