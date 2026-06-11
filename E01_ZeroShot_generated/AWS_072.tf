provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "queue_name" {
  type        = string
  default     = "my-sqs-queue"
}

variable "dead_letter_queue_name" {
  type        = string
  default     = "my-sqs-dead-letter-queue"
}

variable "account_id" {
  type        = string
  sensitive   = true
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
  delay_seconds               = 90
  message_retention_period     = 86400
  receive_wait_time_seconds    = 10
}

resource "aws_sqs_queue" "queue" {
  name                        = var.queue_name
  delay_seconds               = 90
  message_retention_period     = 86400
  receive_wait_time_seconds    = 10
  redrive_policy              = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy    = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSendMessage"
        Effect    = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.queue.arn
      },
    ]
  })
}