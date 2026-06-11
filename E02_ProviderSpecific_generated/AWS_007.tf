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
  delay_seconds               = 90
  message_retention_period    = 864000
  receive_wait_time_seconds   = 20
}

resource "aws_sqs_queue" "main_queue" {
  name                        = "main-queue"
  delay_seconds               = 90
  message_retention_period    = 864000
  receive_wait_time_seconds   = 20
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue_policy" "main_queue_policy" {
  queue_url = aws_sqs_queue.main_queue.id
  policy    = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.main_queue.arn
      },
    ]
  })
}