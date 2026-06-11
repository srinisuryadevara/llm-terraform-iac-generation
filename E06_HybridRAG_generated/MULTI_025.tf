# AWS SQS
module "aws_sqs" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-sqs.git?ref=v3.4.0"

  name = var.aws_sqs_name

  visibility_timeout_seconds = 3600
  message_retention_period    = 86400
  delay_seconds              = 90
  receive_wait_time_seconds  = 10

  tags = {
    Environment = var.environment
  }
}

# Azure Service Bus Queue
provider "azurerm" {
  version = "~> 2.0"
  features {}
}

module "azure_service_bus" {
  source = "git::https://github.com/terraform-azurerm-modules/terraform-azurerm-servicebus.git?ref=v1.0.0"

  resource_group_name = var.azure_resource_group_name
  namespace_name      = var.azure_namespace_name
  queue_name          = var.azure_queue_name

  queue_authorization_rules = [
    {
      name = "RootManageSharedAccessKey"
    }
  ]
}

# GCP Pub/Sub
provider "google" {
  version = "~> 3.0"
  project = var.gcp_project
  region  = var.gcp_region
}

module "gcp_pubsub" {
  source = "git::https://github.com/terraform-google-modules/terraform-google-pubsub.git?ref=v1.0.0"

  project_id = var.gcp_project
  topic      = var.gcp_topic

  subscription = var.gcp_subscription
}

variable "aws_sqs_name" {
  type        = string
  description = "The name of the SQS queue"
}

variable "environment" {
  type        = string
  description = "The environment of the SQS queue"
}

variable "azure_resource_group_name" {
  type        = string
  description = "The name of the Azure resource group"
}

variable "azure_namespace_name" {
  type        = string
  description = "The name of the Azure Service Bus namespace"
}

variable "azure_queue_name" {
  type        = string
  description = "The name of the Azure Service Bus queue"
}

variable "gcp_project" {
  type        = string
  description = "The ID of the GCP project"
}

variable "gcp_region" {
  type        = string
  description = "The region of the GCP project"
}

variable "gcp_topic" {
  type        = string
  description = "The name of the GCP Pub/Sub topic"
}

variable "gcp_subscription" {
  type        = string
  description = "The name of the GCP Pub/Sub subscription"
}