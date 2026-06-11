terraform {
  required_version = ">= 1.4, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0, < 6.0"
    }
  }
}

variable "sqs_queue_name" {
  type        = string
  description = "The name of the SQS queue"
}

variable "dead_letter_queue_name" {
  type        = string
  description = "The name of the dead-letter queue"
}

variable "max_receive_count" {
  type        = number
  description = "The maximum number of times a message can be received before being moved to the dead-letter queue"
}

variable "visibility_timeout_seconds" {
  type        = number
  description = "The visibility timeout for the SQS queue"
}

variable "message_retention_period_seconds" {
  type        = number
  description = "The message retention period for the SQS queue"
}

variable "delay_seconds" {
  type        = number
  description = "The delay seconds for the SQS queue"
}

variable "receive_wait_time_seconds" {
  type        = number
  description = "The receive wait time seconds for the SQS queue"
}

variable "policy" {
  type        = string
  description = "The access policy for the SQS queue"
}

resource "aws_sqs_queue" "queue" {
  name                        = var.sqs_queue_name
  delay_seconds               = var.delay_seconds
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  message_retention_period_seconds = var.message_retention_period_seconds
  receive_wait_time_seconds   = var.receive_wait_time_seconds
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = var.max_receive_count
  })
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
}

resource "aws_sqs_queue_policy" "policy" {
  queue_url = aws_sqs_queue.queue.id
  policy    = var.policy
}