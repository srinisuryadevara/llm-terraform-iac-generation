provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "account_id" {
  type        = string
  sensitive   = true
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = "dead-letter-queue"
}

resource "aws_sqs_queue" "main_queue" {
  name                        = "main-queue"
  delay_seconds              = 10
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds = 300
  redrive_policy             = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_policy" "main_queue_policy" {
  queue_url = aws_sqs_queue.main_queue.id
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
        Resource = aws_sqs_queue.main_queue.arn
      },
    ]
  })
}