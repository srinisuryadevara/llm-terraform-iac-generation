provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "sqs_queue_name" {
  type        = string
  description = "SQS Queue Name"
}

variable "dead_letter_queue_name" {
  type        = string
  description = "Dead Letter Queue Name"
}

variable "max_receive_count" {
  type        = number
  default     = 5
  description = "Maximum Receive Count"
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = 300
}

resource "aws_sqs_queue" "sqs_queue" {
  name                        = var.sqs_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = 300
  redrive_policy              = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = var.max_receive_count
  })
}

resource "aws_sqs_queue_policy" "sqs_queue_policy" {
  queue_url = aws_sqs_queue.sqs_queue.id
  policy    = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sqs.amazonaws.com"
        }
        Action = "SQS:SendMessage"
        Resource = aws_sqs_queue.sqs_queue.arn
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = "SQS:ReceiveMessage"
        Resource = aws_sqs_queue.sqs_queue.arn
      },
    ]
  })
}