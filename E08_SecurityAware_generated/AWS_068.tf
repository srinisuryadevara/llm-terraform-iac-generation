provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "project_name" {
  type        = string
  description = "Project Name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "queue_name" {
  type        = string
  description = "SQS Queue Name"
}

variable "dead_letter_queue_name" {
  type        = string
  description = "Dead-Letter SQS Queue Name"
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
  kms_master_key_id           = aws_kms_key.sqs_key.arn
  kms_data_key_reuse_period_seconds = 300
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "queue" {
  name                        = var.queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = 300
  redrive_policy              = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = var.max_receive_count
  })
  kms_master_key_id           = aws_kms_key.sqs_key.arn
  kms_data_key_reuse_period_seconds = 300
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy    = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sqs.amazonaws.com"
        }
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.queue.arn
        Condition = {
          StringLike = {
            "aws:SourceArn" = "arn:aws:sqs:*:*:${var.project_name}-*"
          }
        }
      },
    ]
  })
}

resource "aws_kms_key" "sqs_key" {
  description             = "KMS Key for SQS"
  deletion_window_in_days = 10
  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_kms_alias" "sqs_key_alias" {
  name          = "alias/sqs-key"
  target_key_id = aws_kms_key.sqs_key.key_id
}