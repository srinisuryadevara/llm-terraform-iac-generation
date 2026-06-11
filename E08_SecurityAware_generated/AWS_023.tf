provider "aws" {
  region = var.aws_region
}

resource "aws_sqs_queue" "main_queue" {
  name                        = var.sqs_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 20
  visibility_timeout_seconds  = 300
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = "${var.sqs_queue_name}-dead-letter"
  delay_seconds               = 90
  message_retention_period    = 1209600
  receive_wait_time_seconds   = 20
  visibility_timeout_seconds  = 300
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_sqs_queue_policy" "main_queue_policy" {
  queue_url = aws_sqs_queue.main_queue.id
  policy    = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sqs.amazonaws.com"
        }
        Action = "SQS:SendMessage"
        Resource = aws_sqs_queue.main_queue.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_sqs_queue.dead_letter_queue.arn
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_account_id
        }
        Action = "SQS:SendMessage"
        Resource = aws_sqs_queue.main_queue.arn
      }
    ]
  })
}

resource "aws_sqs_queue_redrive_policy" "main_queue_redrive_policy" {
  queue_url = aws_sqs_queue.main_queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 5
  })
}