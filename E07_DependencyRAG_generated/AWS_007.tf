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
  default     = 5
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = 900
}

resource "aws_sqs_queue" "main_queue" {
  name                        = var.sqs_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = 900
  redrive_policy              = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = var.max_receive_count
  })
}

resource "aws_sqs_queue_policy" "main_queue_policy" {
  queue_url = aws_sqs_queue.main_queue.id

  policy    = jsonencode({
    Version = "2012-10-17"
    Id      = "sqspolicy"
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
      {
        Sid       = "AllowReceiveMessage"
        Effect    = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = "sqs:ReceiveMessage"
        Resource = aws_sqs_queue.main_queue.arn
      },
      {
        Sid       = "AllowDeleteMessage"
        Effect    = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = "sqs:DeleteMessage"
        Resource = aws_sqs_queue.main_queue.arn
      },
    ]
  })
}