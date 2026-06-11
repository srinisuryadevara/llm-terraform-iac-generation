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
  description = "Maximum Receive Count"
  default     = 5
}

variable "visibility_timeout_seconds" {
  type        = number
  description = "Visibility Timeout Seconds"
  default     = 300
}

variable "message_retention_period" {
  type        = number
  description = "Message Retention Period"
  default     = 1209600
}

provider "aws" {
  region = var.aws_region
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
  delay_seconds               = 0
  message_retention_period    = var.message_retention_period
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = var.visibility_timeout_seconds
}

resource "aws_sqs_queue" "sqs_queue" {
  name                        = var.sqs_queue_name
  delay_seconds               = 0
  message_retention_period    = var.message_retention_period
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  redrive_policy              = jsonencode({
    dead_letter_target_arn = aws_sqs_queue.dead_letter_queue.arn
    max_receive_count      = var.max_receive_count
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
          ArnLike = {
            "aws:SourceArn" = "arn:aws:s3:::example-bucket"
          }
        }
      }
    ]
  })
}