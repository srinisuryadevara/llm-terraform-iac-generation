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
  description = "SQS Dead-Letter Queue Name"
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
        Action = "SQS:SendMessage"
        Resource = aws_sqs_queue.queue.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_sqs_queue.dead_letter_queue.arn
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.sqs_role.arn
        }
        Action = "SQS:ReceiveMessage"
        Resource = aws_sqs_queue.queue.arn
      }
    ]
  })
}

resource "aws_iam_role" "sqs_role" {
  name        = "sqs-role"
  description = "IAM Role for SQS"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "sqs.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_policy" "sqs_policy" {
  name        = "sqs-policy"
  description = "IAM Policy for SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = aws_sqs_queue.queue.arn
        Effect    = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sqs_attach" {
  role       = aws_iam_role.sqs_role.name
  policy_arn = aws_iam_policy.sqs_policy.arn
}