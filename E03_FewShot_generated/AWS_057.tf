variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "sns_topic_name" {
  type        = string
  description = "SNS Topic Name"
}

variable "email_subscription_address" {
  type        = string
  description = "Email Subscription Address"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_sns_topic" "this" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.email_subscription_address
}