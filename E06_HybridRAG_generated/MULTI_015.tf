# AWS SQS Queue
resource "aws_sqs_queue" "sqs_queue" {
  name                        = var.sqs_queue_name
  delay_seconds               = var.sqs_delay_seconds
  message_retention_period    = var.sqs_message_retention_period
  receive_wait_time_seconds   = var.sqs_receive_wait_time_seconds
  visibility_timeout_seconds  = var.sqs_visibility_timeout_seconds
}

data "aws_iam_policy_document" "sqs_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SQS:SendMessage",
    ]

    condition {
      test     = "ArnEquals"
      variable = "AWS:SourceARN"

      values = [
        "${aws_sns_topic.sns_topic.arn}",
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "${aws_sqs_queue.sqs_queue.arn}",
    ]
  }
}

resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = "${aws_sqs_queue.sqs_queue.id}"
  policy    = "${data.aws_iam_policy_document.sqs_policy.json}"
}

# Azure Service Bus Queue
provider "azurerm" {
  version = "~>2.0"
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_servicebus_namespace" "servicebus_namespace" {
  name                = var.servicebus_namespace_name
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = var.servicebus_sku
}

resource "azurerm_servicebus_queue" "servicebus_queue" {
  name                = var.servicebus_queue_name
  resource_group_name = azurerm_resource_group.resource_group.name
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
}

# GCP Pub/Sub
provider "google" {
  version = "~>3.0"
  project = var.project_id
  region  = var.region
}

resource "google_pubsub_topic" "pubsub_topic" {
  name = var.pubsub_topic_name
}

resource "google_pubsub_subscription" "pubsub_subscription" {
  name  = var.pubsub_subscription_name
  topic = google_pubsub_topic.pubsub_topic.name
}

variable "sqs_queue_name" {
  type        = string
  description = "The name of the SQS queue"
}

variable "sqs_delay_seconds" {
  type        = number
  description = "The delay seconds of the SQS queue"
}

variable "sqs_message_retention_period" {
  type        = number
  description = "The message retention period of the SQS queue"
}

variable "sqs_receive_wait_time_seconds" {
  type        = number
  description = "The receive wait time seconds of the SQS queue"
}

variable "sqs_visibility_timeout_seconds" {
  type        = number
  description = "The visibility timeout seconds of the SQS queue"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "servicebus_namespace_name" {
  type        = string
  description = "The name of the service bus namespace"
}

variable "servicebus_sku" {
  type        = string
  description = "The SKU of the service bus namespace"
}

variable "servicebus_queue_name" {
  type        = string
  description = "The name of the service bus queue"
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region of the project"
}

variable "pubsub_topic_name" {
  type        = string
  description = "The name of the pub/sub topic"
}

variable "pubsub_subscription_name" {
  type        = string
  description = "The name of the pub/sub subscription"
}