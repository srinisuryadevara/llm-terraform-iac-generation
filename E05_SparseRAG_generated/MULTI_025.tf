# AWS SQS
resource "aws_sqs_queue" "aws_sqs_queue" {
  name                        = "my-aws-sqs-queue"
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = 300
}

data "aws_iam_policy_document" "aws_sqs_policy_document" {
  statement {
    actions = [
      "SQS:SendMessage",
    ]

    condition {
      test     = "ArnEquals"
      variable = "AWS:SourceARN"

      values = [
        "${aws_sns_topic.aws_sns_topic.arn}",
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "${aws_sqs_queue.aws_sqs_queue.arn}",
    ]
  }
}

resource "aws_sqs_queue_policy" "aws_sqs_queue_policy" {
  queue_url = "${aws_sqs_queue.aws_sqs_queue.id}"
  policy    = "${data.aws_iam_policy_document.aws_sqs_policy_document.json}"
}

resource "aws_sns_topic" "aws_sns_topic" {
  name = "my-aws-sns-topic"
}

resource "aws_sns_topic_policy" "aws_sns_topic_policy" {
  arn    = "${aws_sns_topic.aws_sns_topic.arn}"
  policy = "${data.aws_iam_policy_document.aws_sns_topic_policy_document.json}"
}

data "aws_iam_policy_document" "aws_sns_topic_policy_document" {
  statement {
    actions = [
      "SNS:Publish",
    ]

    condition {
      test     = "ArnEquals"
      variable = "AWS:SourceARN"

      values = [
        "${aws_s3_bucket.aws_s3_bucket.arn}",
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "${aws_sns_topic.aws_sns_topic.arn}",
    ]

    sid = "allow_publish"
  }

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:Receive",
    ]

    condition {
      test     = "StringLike"
      variable = "SNS:Endpoint"

      values = [
        "${aws_sns_topic.aws_sns_topic.arn}",
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "${aws_sqs_queue.aws_sqs_queue.arn}",
    ]

    sid = "allow_subscription"
  }
}

resource "aws_sns_topic_subscription" "aws_sns_topic_subscription" {
  topic_arn = "${aws_sns_topic.aws_sns_topic.arn}"
  protocol  = "sqs"
  endpoint  = "${aws_sqs_queue.aws_sqs_queue.arn}"
}

resource "aws_s3_bucket" "aws_s3_bucket" {
  bucket = "my-aws-s3-bucket"
}

# Azure Service Bus Queue
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "azurerm_resource_group" {
  name     = "my-azurerm-resource-group"
  location = "West US"
}

resource "azurerm_servicebus_namespace" "azurerm_servicebus_namespace" {
  name                = "my-azurerm-servicebus-namespace"
  location            = azurerm_resource_group.azurerm_resource_group.location
  resource_group_name = azurerm_resource_group.azurerm_resource_group.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "azurerm_servicebus_queue" {
  name                = "my-azurerm-servicebus-queue"
  resource_group_name = azurerm_resource_group.azurerm_resource_group.name
  namespace_name      = azurerm_servicebus_namespace.azurerm_servicebus_namespace.name
  enable_partitioning = true
}

# GCP Pub/Sub
provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_pubsub_topic" "google_pubsub_topic" {
  name = "my-google-pubsub-topic"
}

resource "google_pubsub_subscription" "google_pubsub_subscription" {
  name  = "my-google-pubsub-subscription"
  topic = google_pubsub_topic.google_pubsub_topic.name
}

resource "google_iam_policy" "google_iam_policy" {
  binding {
    role = "roles/pubsub.publisher"

    members = [
      "allUsers",
    ]
  }

  binding {
    role = "roles/pubsub.subscriber"

    members = [
      "allUsers",
    ]
  }
}

resource "google_pubsub_topic_iam_policy" "google_pubsub_topic_iam_policy" {
  project     = var.project_id
  topic       = google_pubsub_topic.google_pubsub_topic.name
  policy_data = google_iam_policy.google_iam_policy.policy_data
}