provider "aws" {
  region = var.aws_region
}

resource "aws_sns_topic" "email_topic" {
  name = var.sns_topic_name

  tags = {
    Name        = var.sns_topic_name
    Environment = "production"
  }
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.email_topic.arn
  protocol  = "email"
  endpoint  = var.email_address

  tags = {
    Name        = "${var.sns_topic_name}-subscription"
    Environment = "production"
  }
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "sns_topic_name" {
  type        = string
  sensitive   = false
}

variable "email_address" {
  type        = string
  sensitive   = true
}

output "sns_topic_arn" {
  value       = aws_sns_topic.email_topic.arn
  description = "The ARN of the SNS topic"
}

output "sns_topic_name" {
  value       = aws_sns_topic.email_topic.name
  description = "The name of the SNS topic"
}

output "sns_subscription_arn" {
  value       = aws_sns_topic_subscription.email_subscription.arn
  description = "The ARN of the SNS topic subscription"
}