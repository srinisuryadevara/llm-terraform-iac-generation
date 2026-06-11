# AWS SQS
provider "aws" {
  region = var.aws_region
}

resource "aws_sqs_queue" "aws_sqs_queue" {
  name                        = var.aws_sqs_queue_name
  delay_seconds               = var.aws_sqs_delay_seconds
  message_retention_period    = var.aws_sqs_message_retention_period
  receive_wait_time_seconds   = var.aws_sqs_receive_wait_time_seconds
  visibility_timeout_seconds  = var.aws_sqs_visibility_timeout_seconds
}

# Azure Service Bus Queue
provider "azurerm" {
  version = "~>2.0"
  features {}
}

resource "azurerm_servicebus_queue" "azure_servicebus_queue" {
  name                = var.azure_servicebus_queue_name
  resource_group_name = var.azure_resource_group_name
  namespace_name      = var.azure_namespace_name
  enable_partitioning = var.azure_enable_partitioning
}

# GCP Pub/Sub
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_pubsub_topic" "gcp_pubsub_topic" {
  name = var.gcp_pubsub_topic_name
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_sqs_queue_name" {
  type        = string
  description = "AWS SQS Queue Name"
}

variable "aws_sqs_delay_seconds" {
  type        = number
  description = "AWS SQS Delay Seconds"
}

variable "aws_sqs_message_retention_period" {
  type        = number
  description = "AWS SQS Message Retention Period"
}

variable "aws_sqs_receive_wait_time_seconds" {
  type        = number
  description = "AWS SQS Receive Wait Time Seconds"
}

variable "aws_sqs_visibility_timeout_seconds" {
  type        = number
  description = "AWS SQS Visibility Timeout Seconds"
}

variable "azure_resource_group_name" {
  type        = string
  description = "Azure Resource Group Name"
}

variable "azure_namespace_name" {
  type        = string
  description = "Azure Namespace Name"
}

variable "azure_servicebus_queue_name" {
  type        = string
  description = "Azure Service Bus Queue Name"
}

variable "azure_enable_partitioning" {
  type        = bool
  description = "Azure Enable Partitioning"
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