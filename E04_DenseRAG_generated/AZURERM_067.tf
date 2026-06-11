terraform {
  required_version = ">= 1.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.59.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "az_res_group" {
  type        = string
  description = "The name of the Azure resource group"
}

variable "az_acr_name" {
  type        = string
  description = "The name of the Azure Container Registry"
}

variable "az_acr_sku" {
  type        = string
  description = "The SKU of the Azure Container Registry"
}

variable "az_tags" {
  type        = map(string)
  description = "The tags for the Azure Container Registry"
}

# Get the main Azure resource group.
data "azurerm_resource_group" "acr" {
  name = var.az_res_group
}

# Create a ACR instance in the resource group.
resource "azurerm_container_registry" "acr" {
  name                = var.az_acr_name
  resource_group_name = data.azurerm_resource_group.acr.name
  location            = data.azurerm_resource_group.acr.location
  sku                 = var.az_acr_sku
  tags                = var.az_tags

  # Admin access is disabled.
  admin_enabled = false
}