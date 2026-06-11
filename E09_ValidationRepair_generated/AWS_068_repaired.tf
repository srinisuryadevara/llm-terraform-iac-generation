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
  description = "Maximum Receive Count"
  default     = 5
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = 300
  tags = {
    Name        = var.dead_letter_queue_name
    Environment = "production"
  }
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
  tags = {
    Name        = var.sqs_queue_name
    Environment = "production"
  }
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
            "aws:SourceArn" = "arn:aws:s3:::*"
          }
        }
      },
    ]
  })
  tags = {
    Name        = "${var.sqs_queue_name}-policy"
    Environment = "production"
  }
}

output "sqs_queue_id" {
  value       = aws_sqs_queue.sqs_queue.id
  description = "The URL of the SQS queue"
}

output "sqs_queue_arn" {
  value       = aws_sqs_queue.sqs_queue.arn
  description = "The ARN of the SQS queue"
}

output "dead_letter_queue_id" {
  value       = aws_sqs_queue.dead_letter_queue.id
  description = "The URL of the dead-letter SQS queue"
}

output "dead_letter_queue_arn" {
  value       = aws_sqs_queue.dead_letter_queue.arn
  description = "The ARN of the dead-letter SQS queue"
}