provider "aws" {
  region = var.region
}

variable "region" {
  type = string
}

variable "queue_name" {
  type = string
}

variable "dead_letter_queue_name" {
  type = string
}

variable "account_id" {
  type = string
}

resource "aws_sqs_queue" "queue" {
  name                        = var.queue_name
  delay_seconds               = 90
  message_retention_period     = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds = 300
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
  delay_seconds               = 90
  message_retention_period     = 1209600
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds = 300
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy    = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sqs.amazonaws.com"
        }
        Action = "SQS:SendMessage"
        Resource = aws_sqs_queue.queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sqs_queue.dead_letter_queue.arn
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action = "SQS:*"
        Resource = aws_sqs_queue.queue.arn
      }
    ]
  })
}

resource "aws_sqs_queue_redrive_policy" "redrive_policy" {
  queue_url = aws_sqs_queue.queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 5
  })
}