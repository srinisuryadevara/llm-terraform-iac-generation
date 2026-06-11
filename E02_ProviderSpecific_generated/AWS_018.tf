provider "aws" {
  region = var.region
}

resource "aws_sns_topic" "example" {
  name = "example-topic"
}

resource "aws_sns_topic_subscription" "example" {
  topic_arn = aws_sns_topic.example.arn
  protocol  = "email"
  endpoint  = var.email_address
}

output "sns_topic_arn" {
  value = aws_sns_topic.example.arn
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "email_address" {
  type        = string
  description = "Email address for SNS subscription"
  sensitive   = true
}