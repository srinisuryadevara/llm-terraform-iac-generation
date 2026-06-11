variable "queue_name" {
  type        = string
  description = "Name of the SQS queue"
}

variable "dead_letter_queue_name" {
  type        = string
  description = "Name of the dead-letter SQS queue"
}

variable "max_receive_count" {
  type        = number
  description = "Maximum number of times a message can be received before being moved to the dead-letter queue"
  default     = 5
}

variable "message_retention_seconds" {
  type        = number
  description = "Number of seconds to retain messages in the queue"
  default     = 86400
}

variable "visibility_timeout_seconds" {
  type        = number
  description = "Number of seconds to wait before receiving a message again"
  default     = 30
}

variable "delay_seconds" {
  type        = number
  description = "Number of seconds to delay before delivering a message"
  default     = 0
}

variable "policy_actions" {
  type        = list(string)
  description = "List of actions to allow in the SQS queue policy"
  default     = ["SQS:SendMessage", "SQS:ReceiveMessage", "SQS:DeleteMessage", "SQS:GetQueueAttributes"]
}

variable "policy_principals" {
  type        = list(string)
  description = "List of principals to allow in the SQS queue policy"
  default     = ["*"]
}

resource "aws_sqs_queue" "queue" {
  name                        = var.queue_name
  delay_seconds               = var.delay_seconds
  message_retention_period    = var.message_retention_seconds
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  receive_wait_time_seconds   = 10
  redrive_policy              = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = var.max_receive_count
  })
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.dead_letter_queue_name
  delay_seconds               = var.delay_seconds
  message_retention_period    = var.message_retention_seconds
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  receive_wait_time_seconds   = 10
}

data "aws_iam_policy_document" "sqs_policy" {
  statement {
    actions = var.policy_actions

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
      identifiers = var.policy_principals
    }

    resources = [
      aws_sqs_queue.queue.arn,
    ]
  }
}

resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy    = data.aws_iam_policy_document.sqs_policy.json
}