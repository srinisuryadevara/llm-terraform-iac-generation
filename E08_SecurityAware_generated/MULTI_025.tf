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
resource "aws_sqs_queue" "secure_sqs_queue" {
  name                        = var.aws_sqs_queue_name
  delay_seconds               = 90
  message_retention_period    = 86400
  receive_wait_time_seconds   = 10
  visibility_timeout_seconds  = 300
  kms_master_key_id           = aws_kms_key.sqs_key.arn
  kms_data_key_reuse_period_seconds = 300
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# AWS KMS Key for SQS
resource "aws_kms_key" "sqs_key" {
  description             = "KMS Key for SQS"
  deletion_window_in_days = 10
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# Azure Service Bus Queue
resource "azurerm_servicebus_queue" "secure_servicebus_queue" {
  name                = var.azure_servicebus_queue_name
  resource_group_name = var.azure_resource_group_name
  namespace_name      = var.azure_servicebus_namespace_name
  enable_partitioning = true
  requires_duplicate_detection = true
  default_message_time_to_live = "P14D"
  lock_duration          = "PT5M"
  max_size_in_megabytes  = 5120
  requires_session       = false
  auto_delete_on_idle    = "P10675199DT2H48M5.4775807S"
  duplicate_detection_history_time_window = "PT10M"
  dead_lettering_on_message_corruption = true
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# Azure Service Bus Namespace
resource "azurerm_servicebus_namespace" "secure_servicebus_namespace" {
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
resource "google_pubsub_topic" "secure_pubsub_topic" {
  name       = var.gcp_pubsub_topic_name
  project    = var.gcp_project
  kms_key    = google_kms_crypto_key.pubsub_key.id
  labels = {
    Environment = var.environment
    Project     = var.project
  }
}

# GCP KMS Key for Pub/Sub
resource "google_kms_key_ring" "pubsub_key_ring" {
  name     = "pubsub-key-ring"
  location = var.gcp_location
  project  = var.gcp_project
}

resource "google_kms_crypto_key" "pubsub_key" {
  name            = "pubsub-key"
  key_ring        = google_kms_key_ring.pubsub_key_ring.id
  rotation_period = "7776000s"
  project         = var.gcp_project
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

variable "gcp_location" {
  type        = string
  description = "GCP Location"
}

variable "gcp_pubsub_topic_name" {
  type        = string
  description = "GCP Pub/Sub Topic Name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "project" {
  type        = string
  description = "Project"
}