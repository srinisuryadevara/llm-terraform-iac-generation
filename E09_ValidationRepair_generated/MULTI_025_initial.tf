# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# AWS SQS
resource "aws_sqs_queue" "aws_sqs_queue" {
  name                        = var.aws_sqs_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = 300
}

# Azure Service Bus Queue
resource "azurerm_servicebus_namespace" "az_servicebus_namespace" {
  name                = var.az_servicebus_namespace_name
  location            = var.az_location
  resource_group_name = var.az_resource_group_name
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "az_servicebus_queue" {
  name                = var.az_servicebus_queue_name
  namespace_name      = azurerm_servicebus_namespace.az_servicebus_namespace.name
  resource_group_name = var.az_resource_group_name
}

# GCP Pub/Sub
resource "google_pubsub_topic" "gcp_pubsub_topic" {
  name = var.gcp_pubsub_topic_name
}

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

variable "az_location" {
  type        = string
  sensitive   = true
}

variable "az_resource_group_name" {
  type        = string
  sensitive   = true
}

variable "az_servicebus_namespace_name" {
  type        = string
  sensitive   = true
}

variable "az_servicebus_queue_name" {
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