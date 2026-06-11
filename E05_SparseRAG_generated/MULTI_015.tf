# AWS SQS
resource "aws_sqs_queue" "aws_sqs_queue" {
  name                        = var.aws_sqs_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  sqs_managed_sse_enabled     = true
  visibility_timeout_seconds  = 300
  tags                        = var.aws_tags
}

data "aws_iam_policy_document" "aws_sqs_policy" {
  policy_id = "__default_policy_ID"

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

resource "aws_sqs_queue_policy" "aws_sqs_policy" {
  queue_url = "${aws_sqs_queue.aws_sqs_queue.id}"
  policy    = "${data.aws_iam_policy_document.aws_sqs_policy.json}"
}

resource "aws_sns_topic" "aws_sns_topic" {
  name = var.aws_sns_topic_name
}

resource "aws_sns_topic_policy" "aws_sns_topic_policy" {
  arn    = "${aws_sns_topic.aws_sns_topic.arn}"
  policy = "${data.aws_iam_policy_document.aws_sns_topic_policy.json}"
}

data "aws_iam_policy_document" "aws_sns_topic_policy" {
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
  bucket = var.aws_s3_bucket_name
  acl    = "private"

  tags = var.aws_tags
}

# Azure Service Bus Queue
resource "azurerm_resource_group" "azure_resource_group" {
  name     = var.azure_resource_group_name
  location = var.azure_location
}

resource "azurerm_servicebus_namespace" "azure_servicebus_namespace" {
  name                = var.azure_servicebus_namespace_name
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "azure_servicebus_queue" {
  name                = var.azure_servicebus_queue_name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  namespace_name      = azurerm_servicebus_namespace.azure_servicebus_namespace.name
}

resource "azurerm_servicebus_queue_authorization_rule" "azure_servicebus_queue_authorization_rule" {
  name                = var.azure_servicebus_queue_authorization_rule_name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  namespace_name      = azurerm_servicebus_namespace.azure_servicebus_namespace.name
  queue_name          = azurerm_servicebus_queue.azure_servicebus_queue.name
  rights              = ["Send", "Listen"]
}

# GCP Pub/Sub
resource "google_project" "gcp_project" {
  project_id = var.gcp_project_id
}

resource "google_pubsub_topic" "gcp_pubsub_topic" {
  name = var.gcp_pubsub_topic_name
}

resource "google_pubsub_subscription" "gcp_pubsub_subscription" {
  name  = var.gcp_pubsub_subscription_name
  topic = google_pubsub_topic.gcp_pubsub_topic.name
}

resource "google_iam_policy" "gcp_iam_policy" {
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

resource "google_pubsub_topic_iam_policy" "gcp_pubsub_topic_iam_policy" {
  project     = google_project.gcp_project.project_id
  topic       = google_pubsub_topic.gcp_pubsub_topic.name
  policy_data = google_iam_policy.gcp_iam_policy.policy_data
}