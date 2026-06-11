provider "aws" {
  region = var.region
}

resource "aws_sns_topic" "example" {
  name = "example-sns-topic"
}

resource "aws_sns_topic_subscription" "example" {
  topic_arn = aws_sns_topic.example.arn
  protocol  = "email"
  endpoint  = var.email_endpoint
}