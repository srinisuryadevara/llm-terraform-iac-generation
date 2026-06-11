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

# AWS SQS Queue
resource "aws_sqs_queue" "example" {
  name                        = var.aws_sqs_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = 300
  kms_master_key_id           = aws_kms_key.example.arn
  kms_data_key_reuse_period_seconds = 300

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# AWS KMS Key for SQS Encryption
resource "aws_kms_key" "example" {
  description             = "KMS Key for SQS Encryption"
  deletion_window_in_days = 10

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# Azure Service Bus Queue
resource "azurerm_servicebus_queue" "example" {
  name                = var.azure_servicebus_queue_name
  resource_group_name = var.azure_resource_group_name
  namespace_name      = var.azure_servicebus_namespace_name
  enable_partitioning = true

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# Azure Service Bus Namespace
resource "azurerm_servicebus_namespace" "example" {
  name                = var.azure_servicebus_namespace_name
  location            = var.azure_location
  resource_group_name = var.azure_resource_group_name
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# GCP Pub/Sub Topic
resource "google_pubsub_topic" "example" {
  name = var.gcp_pubsub_topic_name

  labels = {
    Environment = var.environment
    Project     = var.project
  }
}

# GCP Pub/Sub Subscription
resource "google_pubsub_subscription" "example" {
  name  = var.gcp_pubsub_subscription_name
  topic = google_pubsub_topic.example.name

  labels = {
    Environment = var.environment
    Project     = var.project
  }
}

# GCP KMS Keyring for Pub/Sub Encryption
resource "google_kms_key_ring" "example" {
  name     = var.gcp_kms_keyring_name
  location = var.gcp_location

  labels = {
    Environment = var.environment
    Project     = var.project
  }
}

# GCP KMS Key for Pub/Sub Encryption
resource "google_kms_crypto_key" "example" {
  name            = var.gcp_kms_crypto_key_name
  key_ring        = google_kms_key_ring.example.id
  rotation_period = "7776000s"

  labels = {
    Environment = var.environment
    Project     = var.project
  }
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_sqs_queue_name" {
  type        = string
  description = "AWS SQS Queue Name"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "azure_client_id" {
  type        = string
  description = "Azure Client ID"
}

variable "azure_client_secret" {
  type        = string
  description = "Azure Client Secret"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "azure_servicebus_queue_name" {
  type        = string
  description = "Azure Service Bus Queue Name"
}

variable "azure_resource_group_name" {
  type        = string
  description = "Azure Resource Group Name"
}

variable "azure_servicebus_namespace_name" {
  type        = string
  description = "Azure Service Bus Namespace Name"
}

variable "azure_location" {
  type        = string
  description = "Azure Location"
}

variable "gcp_project" {
  type        = string
  description = "GCP Project"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}

variable "gcp_pubsub_topic_name" {
  type        = string
  description = "GCP Pub/Sub Topic Name"
}

variable "gcp_pubsub_subscription_name" {
  type        = string
  description = "GCP Pub/Sub Subscription Name"
}

variable "gcp_kms_keyring_name" {
  type        = string
  description = "GCP KMS Keyring Name"
}

variable "gcp_kms_crypto_key_name" {
  type        = string
  description = "GCP KMS Crypto Key Name"
}

variable "gcp_location" {
  type        = string
  description = "GCP Location"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "project" {
  type        = string
  description = "Project"
}