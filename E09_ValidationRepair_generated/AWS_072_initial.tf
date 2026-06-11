provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "sqs_queue_name" {
  type        = string
  default     = "my-sqs-queue"
}

variable "dead_letter_queue_name" {
  type        = string
  default     = "my-dead-letter-queue"
}

variable "max_receive_count" {
  type        = number
  default     = 5
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
}

resource "aws_sqs_queue" "sqs_queue" {
  name                        = var.sqs_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
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
          Service = "s3.amazonaws.com"
        }
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.sqs_queue.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.aws_account_id
          }
        }
      },
    ]
  })
}

variable "aws_account_id" {
  type        = string
  sensitive   = true
}