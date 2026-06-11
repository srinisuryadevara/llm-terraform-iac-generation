provider "aws" {
  region = var.aws_region
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 20
  visibility_timeout_seconds  = 300
}

resource "aws_sqs_queue" "main_queue" {
  name                        = var.main_queue_name
  delay_seconds               = 0
  message_retention_period    = 86400
  receive_wait_time_seconds   = 20
  visibility_timeout_seconds  = 300
  redrive_policy              = jsonencode({
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
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.main_queue.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = var.s3_bucket_arn
          }
        }
      }
    ]
  })
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "dead_letter_queue_name" {
  type        = string
  sensitive   = true
}

variable "main_queue_name" {
  type        = string
  sensitive   = true
}

variable "s3_bucket_arn" {
  type        = string
  sensitive   = true
}