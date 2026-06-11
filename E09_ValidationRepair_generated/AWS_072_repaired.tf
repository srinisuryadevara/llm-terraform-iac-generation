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

variable "aws_account_id" {
  type        = string
  sensitive   = true
}

variable "environment" {
  type        = string
  default     = "dev"
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  tags = {
    Name        = var.dead_letter_queue_name
    Environment = var.environment
  }
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
  tags = {
    Name        = var.sqs_queue_name
    Environment = var.environment
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
          StringEquals = {
            "aws:SourceAccount" = var.aws_account_id
          }
        }
      },
    ]
  })
}

output "sqs_queue_id" {
  value       = aws_sqs_queue.sqs_queue.id
  description = "The ID of the SQS queue"
}

output "sqs_queue_arn" {
  value       = aws_sqs_queue.sqs_queue.arn
  description = "The ARN of the SQS queue"
}

output "sqs_queue_url" {
  value       = aws_sqs_queue.sqs_queue.url
  description = "The URL of the SQS queue"
}

output "dead_letter_queue_id" {
  value       = aws_sqs_queue.dead_letter_queue.id
  description = "The ID of the dead-letter SQS queue"
}

output "dead_letter_queue_arn" {
  value       = aws_sqs_queue.dead_letter_queue.arn
  description = "The ARN of the dead-letter SQS queue"
}

output "dead_letter_queue_url" {
  value       = aws_sqs_queue.dead_letter_queue.url
  description = "The URL of the dead-letter SQS queue"
}