# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Configure the GCP Provider
provider "google" {
  project = "your-project-id"
  region  = "us-central1"
}

# Create an AWS SQS Queue
resource "aws_sqs_queue" "aws_sqs_queue" {
  name                        = "aws-sqs-queue"
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = 300
}

# Create an Azure Service Bus Queue
resource "azurerm_servicebus_namespace" "azure_servicebus_namespace" {
  name                = "azure-servicebus-namespace"
  location            = "West US"
  resource_group_name = "your-resource-group-name"
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "azure_servicebus_queue" {
  name                = "azure-servicebus-queue"
  namespace_name      = azurerm_servicebus_namespace.azure_servicebus_namespace.name
  resource_group_name = azurerm_servicebus_namespace.azure_servicebus_namespace.resource_group_name
}

# Create a GCP Pub/Sub Topic
resource "google_pubsub_topic" "gcp_pubsub_topic" {
  name = "gcp-pubsub-topic"
}

# Create a GCP Pub/Sub Subscription
resource "google_pubsub_subscription" "gcp_pubsub_subscription" {
  name  = "gcp-pubsub-subscription"
  topic = google_pubsub_topic.gcp_pubsub_topic.name
}

# Output the ARNs and IDs of the created resources
output "aws_sqs_queue_arn" {
  value = aws_sqs_queue.aws_sqs_queue.arn
}

output "azure_servicebus_queue_id" {
  value = azurerm_servicebus_queue.azure_servicebus_queue.id
}

output "gcp_pubsub_topic_id" {
  value = google_pubsub_topic.gcp_pubsub_topic.id
}

output "gcp_pubsub_subscription_id" {
  value = google_pubsub_subscription.gcp_pubsub_subscription.id
}