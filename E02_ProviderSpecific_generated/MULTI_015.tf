provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "aws_sqs_queue" "aws_message_queue" {
  name                        = var.aws_sqs_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds = 300
}

resource "azurerm_servicebus_queue" "azure_message_queue" {
  name                = var.azure_servicebus_queue_name
  resource_group_name = var.azure_resource_group_name
  namespace_name     = var.azure_servicebus_namespace_name
}

resource "google_pubsub_topic" "gcp_message_queue" {
  name = var.gcp_pubsub_topic_name
}

resource "google_pubsub_subscription" "gcp_message_queue_subscription" {
  name  = var.gcp_pubsub_subscription_name
  topic = google_pubsub_topic.gcp_message_queue.name
}

output "aws_sqs_queue_url" {
  value = aws_sqs_queue.aws_message_queue.id
}

output "azure_servicebus_queue_id" {
  value = azurerm_servicebus_queue.azure_message_queue.id
}

output "gcp_pubsub_topic_id" {
  value = google_pubsub_topic.gcp_message_queue.id
}

output "gcp_pubsub_subscription_id" {
  value = google_pubsub_subscription.gcp_message_queue_subscription.id
}

variable "aws_region" {
  type = string
}

variable "aws_sqs_queue_name" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_client_id" {
  type = string
}

variable "azure_client_secret" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "azure_servicebus_queue_name" {
  type = string
}

variable "azure_resource_group_name" {
  type = string
}

variable "azure_servicebus_namespace_name" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_pubsub_topic_name" {
  type = string
}

variable "gcp_pubsub_subscription_name" {
  type = string
}