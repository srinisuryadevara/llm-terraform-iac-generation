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

variable "message_retention_seconds" {
  type        = number
  description = "The number of seconds Amazon SQS retains a message"
  default     = 86400
}

variable "visibility_timeout_seconds" {
  type        = number
  description = "The visibility timeout for the SQS queue"
  default     = 300
}

variable "delay_seconds" {
  type        = number
  description = "The delay of the SQS queue"
  default     = 0
}

variable "policy_statements" {
  type = list(object({
    actions   = list(string)
    effect    = string
    principals = list(object({
      type        = string
      identifiers = list(string)
    }))
    resources = list(string)
    condition = list(object({
      test     = string
      variable = string
      values   = list(string)
    }))
  }))
  description = "The policy statements for the SQS queue"
}

resource "aws_sqs_queue" "queue" {
  name                       = var.queue_name
  delay_seconds              = var.delay_seconds
  message_retention_period   = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  receive_wait_time_seconds  = 10
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                       = var.dead_letter_queue_name
  delay_seconds              = var.delay_seconds
  message_retention_period   = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  receive_wait_time_seconds  = 10
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy    = data.aws_iam_policy_document.queue_policy_document.json
}

data "aws_iam_policy_document" "queue_policy_document" {
  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sqs_queue.queue.arn,
    ]
  }

  dynamic "statement" {
    for_each = var.policy_statements
    content {
      actions = statement.value.actions

      effect = statement.value.effect

      principals {
        type        = statement.value.principals[0].type
        identifiers = statement.value.principals[0].identifiers
      }

      resources = statement.value.resources

      dynamic "condition" {
        for_each = statement.value.condition
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_sqs_queue_redrive_policy" "queue_redrive_policy" {
  queue_url = aws_sqs_queue.queue.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = var.max_receive_count
  })
}