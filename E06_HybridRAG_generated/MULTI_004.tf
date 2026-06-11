# VARIABLES
variable "aws_region" {
  default = "us-west-2"
}

variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "azure_subscription_id" {}
variable "azure_client_id" {}
variable "azure_client_secret" {}
variable "azure_tenant_id" {}
variable "azure_resource_group_name" {
  default = "example-resource-group"
}
variable "azure_location" {
  default = "West US"
}

variable "gcp_project" {}
variable "gcp_region" {
  default = "us-central1"
}
variable "gcp_credentials" {}

# PROVIDERS
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "azurerm" {
  version = "2.34.0"
  subscription_id = var.azure_subscription_id
  client_id      = var.azure_client_id
  client_secret = var.azure_client_secret
  tenant_id      = var.azure_tenant_id
  features {}
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  credentials = var.gcp_credentials
}

# RESOURCES
resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"
  acl    = "private"

  tags = {
    Name        = "example-bucket"
    Environment = "Dev"
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "examplestorageaccount"
  resource_group_name      = var.azure_resource_group_name
  location                 = var.azure_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "google_storage_bucket" "example" {
  name     = "example-bucket"
  location = var.gcp_region
}