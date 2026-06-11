# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

# Configure the Azure Provider
provider "azurerm" {
  version = "2.34.0"
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
resource "azurerm_servicebus_namespace" "azurerm_servicebus_namespace" {
  name                = "azurerm-servicebus-namespace"
  location            = "West US"
  resource_group_name = "your-resource-group-name"
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "azurerm_servicebus_queue" {
  name                = "azurerm-servicebus-queue"
  resource_group_name = azurerm_servicebus_namespace.azurerm_servicebus_namespace.resource_group_name
  namespace_name      = azurerm_servicebus_namespace.azurerm_servicebus_namespace.name
  enable_partitioning = true
}

# Create a GCP Pub/Sub Topic
resource "google_pubsub_topic" "google_pubsub_topic" {
  name = "google-pubsub-topic"
}

# Create a GCP Pub/Sub Subscription
resource "google_pubsub_subscription" "google_pubsub_subscription" {
  name  = "google-pubsub-subscription"
  topic = google_pubsub_topic.google_pubsub_topic.name
}

# Output the ARNs of the created resources
output "aws_sqs_queue_arn" {
  value = aws_sqs_queue.aws_sqs_queue.arn
}

output "azurerm_servicebus_queue_id" {
  value = azurerm_servicebus_queue.azurerm_servicebus_queue.id
}

output "google_pubsub_topic_id" {
  value = google_pubsub_topic.google_pubsub_topic.id
}