provider "aws" {
  region = var.aws_region
}

resource "aws_sns_topic" "example" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "example" {
  topic_arn = aws_sns_topic.example.arn
  protocol  = "email"
  endpoint  = var.email_endpoint
}