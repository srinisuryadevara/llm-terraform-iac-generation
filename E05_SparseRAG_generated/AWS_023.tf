variable "queue_name" {
  type        = string
  description = "The name of the SQS queue"
}

variable "dead_letter_queue_name" {
  type        = string
  description = "The name of the dead-letter SQS queue"
}

variable "max_receive_count" {
  type        = number
  description = "The maximum number of times a message can be received before being moved to the dead-letter queue"
  default     = 5
}

variable "access_policy_identifiers" {
  type        = list(string)
  description = "The identifiers of the principals that are allowed to access the SQS queue"
  default     = ["*"]
}

resource "aws_sqs_queue" "queue" {
  name                        = var.queue_name
  delay_seconds               = 300
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = 300
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
  delay_seconds               = 300
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = 300
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy    = data.aws_iam_policy_document.queue_policy_document.json
}

data "aws_iam_policy_document" "queue_policy_document" {
  statement {
    actions = [
      "SQS:SendMessage",
    ]

    condition {
      test     = "ArnEquals"
      variable = "AWS:SourceARN"

      values = [
        aws_sqs_queue.queue.arn,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.access_policy_identifiers
    }

    resources = [
      aws_sqs_queue.queue.arn,
    ]
  }

  statement {
    actions = [
      "SQS:ReceiveMessage",
      "SQS:DeleteMessage",
      "SQS:GetQueueAttributes",
    ]

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.access_policy_identifiers
    }

    resources = [
      aws_sqs_queue.queue.arn,
    ]
  }
}

resource "aws_sqs_queue_redrive_policy" "queue_redrive_policy" {
  queue_url = aws_sqs_queue.queue.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = var.max_receive_count
  })
}