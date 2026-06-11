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

variable "sqs_queue_delay_seconds" {
  type        = number
  default     = 0
  description = "The time in seconds that the delivery of all messages in the queue will be delayed"
}

variable "sqs_queue_message_retention_period" {
  type        = number
  default     = 86400
  description = "The number of seconds Amazon SQS retains a message"
}

variable "sqs_queue_visibility_timeout_seconds" {
  type        = number
  default     = 30
  description = "The visibility timeout for the queue, in seconds"
}

variable "dead_letter_queue_message_retention_period" {
  type        = number
  default     = 1209600
  description = "The number of seconds Amazon SQS retains a message in the dead-letter queue"
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
  delay_seconds               = var.sqs_queue_delay_seconds
  message_retention_period    = var.dead_letter_queue_message_retention_period
  visibility_timeout_seconds  = var.sqs_queue_visibility_timeout_seconds
}

resource "aws_sqs_queue" "sqs_queue" {
  name                        = var.sqs_queue_name
  delay_seconds               = var.sqs_queue_delay_seconds
  message_retention_period    = var.sqs_queue_message_retention_period
  visibility_timeout_seconds  = var.sqs_queue_visibility_timeout_seconds
  redrive_policy              = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_policy" "sqs_queue_policy" {
  queue_url = aws_sqs_queue.sqs_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSendMessage"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource = aws_sqs_queue.sqs_queue.arn
      },
      {
        Sid       = "AllowReceiveMessage"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:ReceiveMessage"
        Resource = aws_sqs_queue.sqs_queue.arn
      },
      {
        Sid       = "AllowDeleteMessage"
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:DeleteMessage"
        Resource = aws_sqs_queue.sqs_queue.arn
      },
    ]
  })
}