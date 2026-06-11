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
  tags = {
    Name        = var.sns_topic_name
    Environment = "example"
  }
}

resource "aws_sns_topic_subscription" "example" {
  topic_arn = aws_sns_topic.example.arn
  protocol  = "email"
  endpoint  = var.email_subscription_address
}

output "sns_topic_arn" {
  value       = aws_sns_topic.example.arn
  description = "The ARN of the SNS topic"
}

output "sns_topic_name" {
  value       = aws_sns_topic.example.name
  description = "The name of the SNS topic"
}

output "sns_subscription_arn" {
  value       = aws_sns_topic_subscription.example.arn
  description = "The ARN of the SNS topic subscription"
}