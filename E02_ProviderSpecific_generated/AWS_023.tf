provider "aws" {
  region = var.region
}

variable "region" {
  type = string
}

variable "queue_name" {
  type = string
}

variable "dead_letter_queue_name" {
  type = string
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name = var.dead_letter_queue_name
}

resource "aws_sqs_queue" "queue" {
  name = var.queue_name
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sqs.amazonaws.com"
        }
        Action = "SQS:SendMessage"
        Resource = aws_sqs_queue.queue.arn
      },
    ]
  })
}

resource "aws_sqs_queue_redrive_policy" "redrive_policy" {
  queue_url = aws_sqs_queue.queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount = 5
  })
}