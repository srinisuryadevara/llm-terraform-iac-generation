# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create AWS SQS Queue
resource "aws_sqs_queue" "aws_sqs_queue" {
  name                        = var.aws_sqs_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = 300
}

# Create Azure Service Bus Queue
resource "azurerm_servicebus_queue" "azure_servicebus_queue" {
  name                = var.azure_servicebus_queue_name
  resource_group_name = var.azure_resource_group_name
  namespace_name      = var.azure_servicebus_namespace_name
}

# Create GCP Pub/Sub Topic
resource "google_pubsub_topic" "gcp_pubsub_topic" {
  name = var.gcp_pubsub_topic_name
}

# Create GCP Pub/Sub Subscription
resource "google_pubsub_subscription" "gcp_pubsub_subscription" {
  name  = var.gcp_pubsub_subscription_name
  topic = google_pubsub_topic.gcp_pubsub_topic.name
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "aws_sqs_queue_name" {
  type        = string
  sensitive   = true
}

variable "azure_subscription_id" {
  type        = string
  sensitive   = true
}

variable "azure_client_id" {
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  type        = string
  sensitive   = true
}

variable "azure_tenant_id" {
  type        = string
  sensitive   = true
}

variable "azure_resource_group_name" {
  type        = string
  sensitive   = true
}

variable "azure_servicebus_namespace_name" {
  type        = string
  sensitive   = true
}

variable "azure_servicebus_queue_name" {
  type        = string
  sensitive   = true
}

variable "gcp_project" {
  type        = string
  sensitive   = true
}

variable "gcp_region" {
  type        = string
  sensitive   = true
}

variable "gcp_pubsub_topic_name" {
  type        = string
  sensitive   = true
}

variable "gcp_pubsub_subscription_name" {
  type        = string
  sensitive   = true
}