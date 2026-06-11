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

variable "aws_account_id" {
  type        = string
  description = "The AWS account ID"
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 20
  visibility_timeout_seconds  = 600
}

resource "aws_sqs_queue" "main_queue" {
  name                        = var.sqs_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 20
  visibility_timeout_seconds  = 600
  redrive_policy              = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn,
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_policy" "main_queue_policy" {
  queue_url = aws_sqs_queue.main_queue.id

  policy    = jsonencode({
    Version = "2012-10-17"
    Id      = "sqspolicy"
    Statement = [
      {
        Sid       = "AllowSQSSendMessage"
        Effect    = "Allow"
        Principal = {
          AWS = var.aws_account_id
        }
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.main_queue.arn
      },
      {
        Sid       = "AllowSQSReceiveMessage"
        Effect    = "Allow"
        Principal = {
          AWS = var.aws_account_id
        }
        Action = "sqs:ReceiveMessage"
        Resource = aws_sqs_queue.main_queue.arn
      },
    ]
  })
}