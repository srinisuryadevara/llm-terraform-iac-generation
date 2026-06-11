provider "aws" {
  region = var.aws_region
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
  endpoint  = var.email_address
  tags = {
    Name        = "${var.sns_topic_name}-subscription"
    Environment = "example"
  }
}

output "sns_topic_arn" {
  value       = aws_sns_topic.example.arn
  description = "The ARN of the SNS topic"
}

output "sns_topic_subscription_arn" {
  value       = aws_sns_topic_subscription.example.arn
  description = "The ARN of the SNS topic subscription"
}

output "sns_topic_name" {
  value       = aws_sns_topic.example.name
  description = "The name of the SNS topic"
}