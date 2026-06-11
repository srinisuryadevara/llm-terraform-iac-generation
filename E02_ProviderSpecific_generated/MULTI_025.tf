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

resource "aws_sqs_queue" "aws_queue" {
  name                        = var.aws_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds = 300
}

resource "azurerm_servicebus_queue" "azure_queue" {
  name                = var.azure_queue_name
  resource_group_name  = var.azure_resource_group_name
  namespace_name      = var.azure_namespace_name
  enable_partitioning = true
}

resource "google_pubsub_topic" "gcp_topic" {
  name = var.gcp_topic_name
}

resource "google_pubsub_subscription" "gcp_subscription" {
  name  = var.gcp_subscription_name
  topic = google_pubsub_topic.gcp_topic.name
  ack_deadline_seconds = 10
}

output "aws_queue_url" {
  value = aws_sqs_queue.aws_queue.url
}

output "azure_queue_id" {
  value = azurerm_servicebus_queue.azure_queue.id
}

output "gcp_topic_id" {
  value = google_pubsub_topic.gcp_topic.id
}

output "gcp_subscription_id" {
  value = google_pubsub_subscription.gcp_subscription.id
}

variable "aws_region" {
  type = string
}

variable "aws_queue_name" {
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

variable "azure_resource_group_name" {
  type = string
}

variable "azure_namespace_name" {
  type = string
}

variable "azure_queue_name" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_topic_name" {
  type = string
}

variable "gcp_subscription_name" {
  type = string
}