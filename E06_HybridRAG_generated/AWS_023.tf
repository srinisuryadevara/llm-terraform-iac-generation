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

variable "sqs_dead_letter_queue_name" {
  type        = string
  description = "The name of the SQS dead-letter queue"
}

variable "sqs_queue_tags" {
  type        = map(string)
  description = "The tags for the SQS queue"
}

variable "sqs_dead_letter_queue_tags" {
  type        = map(string)
  description = "The tags for the SQS dead-letter queue"
}

variable "sqs_queue_policy_statements" {
  type = list(object({
    actions = list(string)
    effect  = string
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
  name                        = var.sqs_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 20
  visibility_timeout_seconds  = 300
  redrive_policy              = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 5
  })
  tags                       = var.sqs_queue_tags
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                        = var.sqs_dead_letter_queue_name
  delay_seconds               = 90
  message_retention_period    = 1209600
  receive_wait_time_seconds   = 20
  visibility_timeout_seconds  = 300
  tags                       = var.sqs_dead_letter_queue_tags
}

data "aws_iam_policy_document" "sqs_policy" {
  policy_id = "__default_policy_ID"

  dynamic "statement" {
    for_each = var.sqs_queue_policy_statements

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

resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = aws_sqs_queue.queue.id
  policy    = data.aws_iam_policy_document.sqs_policy.json
}