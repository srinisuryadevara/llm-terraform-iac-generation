provider "aws" {
  region = var.region
}

resource "aws_sns_topic" "topic" {
  name = var.topic_name
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = var.subscription_email
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "topic_name" {
  type        = string
  description = "SNS Topic Name"
}

variable "subscription_email" {
  type        = string
  description = "Email address for SNS subscription"
}