provider "aws" {
  region = var.aws_region
}

resource "aws_sns_topic" "email_topic" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.email_topic.arn
  protocol  = "email"
  endpoint  = var.email_address
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