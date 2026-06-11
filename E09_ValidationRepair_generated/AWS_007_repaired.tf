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
  tags = {
    Name        = var.dead_letter_queue_name
    Environment = "Production"
  }
}

resource "aws_sqs_queue" "main_queue" {
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
    Environment = "Production"
  }
}

resource "aws_sqs_queue_policy" "main_queue_policy" {
  queue_url = aws_sqs_queue.main_queue.id
  policy    = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSendMessage"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.main_queue.arn
      },
      {
        Sid       = "AllowReceiveMessage"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:ReceiveMessage"
        Resource  = aws_sqs_queue.main_queue.arn
      },
      {
        Sid       = "AllowDeleteMessage"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:DeleteMessage"
        Resource  = aws_sqs_queue.main_queue.arn
      },
    ]
  })
  tags = {
    Name        = "${var.sqs_queue_name}-policy"
    Environment = "Production"
  }
}

output "dead_letter_queue_id" {
  value       = aws_sqs_queue.dead_letter_queue.id
  description = "The ID of the dead-letter SQS queue"
}

output "dead_letter_queue_arn" {
  value       = aws_sqs_queue.dead_letter_queue.arn
  description = "The ARN of the dead-letter SQS queue"
}

output "main_queue_id" {
  value       = aws_sqs_queue.main_queue.id
  description = "The ID of the main SQS queue"
}

output "main_queue_arn" {
  value       = aws_sqs_queue.main_queue.arn
  description = "The ARN of the main SQS queue"
}

output "main_queue_url" {
  value       = aws_sqs_queue.main_queue.url
  description = "The URL of the main SQS queue"
}