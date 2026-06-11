provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "sqs_queue_name" {
  type        = string
  sensitive   = false
}

variable "dead_letter_queue_name" {
  type        = string
  sensitive   = false
}

variable "account_id" {
  type        = string
  sensitive   = true
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
  delay_seconds               = 90
  message_retention_period     = 864000
  receive_wait_time_seconds    = 20
}

resource "aws_sqs_queue" "sqs_queue" {
  name                        = var.sqs_queue_name
  delay_seconds               = 0
  message_retention_period     = 864000
  receive_wait_time_seconds    = 20
  redrive_policy              = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_policy" "sqs_queue_policy" {
  queue_url = aws_sqs_queue.sqs_queue.id
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
        Resource = aws_sqs_queue.sqs_queue.arn
      },
      {
        Sid       = "AllowReceiveMessage"
        Effect    = "Allow"
        Principal = {
          AWS = var.account_id
        }
        Action = "sqs:ReceiveMessage"
        Resource = aws_sqs_queue.sqs_queue.arn
      },
    ]
  })
}