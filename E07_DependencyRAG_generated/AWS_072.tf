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
  description = "The name of the dead-letter SQS queue"
}

variable "sqs_queue_visibility_timeout" {
  type        = number
  default     = 30
  description = "The visibility timeout for the SQS queue"
}

variable "dead_letter_queue_visibility_timeout" {
  type        = number
  default     = 30
  description = "The visibility timeout for the dead-letter SQS queue"
}

variable "sqs_queue_message_retention_period" {
  type        = number
  default     = 86400
  description = "The message retention period for the SQS queue"
}

variable "dead_letter_queue_message_retention_period" {
  type        = number
  default     = 86400
  description = "The message retention period for the dead-letter SQS queue"
}

variable "sqs_queue_delay_seconds" {
  type        = number
  default     = 0
  description = "The delay seconds for the SQS queue"
}

variable "dead_letter_queue_delay_seconds" {
  type        = number
  default     = 0
  description = "The delay seconds for the dead-letter SQS queue"
}

variable "sqs_queue_receive_wait_time_seconds" {
  type        = number
  default     = 10
  description = "The receive wait time seconds for the SQS queue"
}

variable "dead_letter_queue_receive_wait_time_seconds" {
  type        = number
  default     = 10
  description = "The receive wait time seconds for the dead-letter SQS queue"
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
  visibility_timeout_seconds  = var.dead_letter_queue_visibility_timeout
  message_retention_period    = var.dead_letter_queue_message_retention_period
  delay_seconds               = var.dead_letter_queue_delay_seconds
  receive_wait_time_seconds   = var.dead_letter_queue_receive_wait_time_seconds
}

resource "aws_sqs_queue" "sqs_queue" {
  name                        = var.sqs_queue_name
  visibility_timeout_seconds  = var.sqs_queue_visibility_timeout
  message_retention_period    = var.sqs_queue_message_retention_period
  delay_seconds               = var.sqs_queue_delay_seconds
  receive_wait_time_seconds   = var.sqs_queue_receive_wait_time_seconds
  redrive_policy              = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn,
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_policy" "sqs_queue_policy" {
  queue_url = aws_sqs_queue.sqs_queue.id

  policy = jsonencode({
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
          Service = "sqs.amazonaws.com"
        }
        Action = "SQS:ReceiveMessage"
        Resource = aws_sqs_queue.sqs_queue.arn
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "sqs.amazonaws.com"
        }
        Action = "SQS:DeleteMessage"
        Resource = aws_sqs_queue.sqs_queue.arn
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "sqs.amazonaws.com"
        }
        Action = "SQS:PurgeQueue"
        Resource = aws_sqs_queue.sqs_queue.arn
      }
    ]
  })
}

output "sqs_queue_arn" {
  value       = aws_sqs_queue.sqs_queue.arn
  description = "The ARN of the SQS queue"
}

output "dead_letter_queue_arn" {
  value       = aws_sqs_queue.dead_letter_queue.arn
  description = "The ARN of the dead-letter SQS queue"
}