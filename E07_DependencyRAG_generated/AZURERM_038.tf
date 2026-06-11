terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.47.0"
    }
  }
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "cdn_profile_name" {
  type = string
}

variable "cdn_endpoint_name" {
  type = string
}

variable "origin_path" {
  type    = string
  default = "/"
}

variable "query_string_caching_behavior" {
  type    = string
  default = "UseQueryString"
}

variable "tags" {
  type = map(string)
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_cdn_profile" "cdn_profile" {
  name                = var.cdn_profile_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "cdn_endpoint" {
  name                = var.cdn_endpoint_name
  profile_name        = azurerm_cdn_profile.cdn_profile.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  origin {
    name       = "storage-origin"
    host_name  = azurerm_storage_account.storage_account.primary_blob_host
    http_port  = 80
    https_port = 443
  }

  origin_group {
    name                = "storage-origin-group"
    health_probe_path   = var.origin_path
    traffic_routing_method = "Geographic"
  }

  delivery_rule {
    name  = "storage-delivery-rule"
    order = 1

    url_file_extension_condition {
      operator           = "Any"
      match_values       = ["*"]
    }

    url_rewrite_action {
      destination_path = var.origin_path
      source_path       = var.origin_path
    }

    modify_response_header_action {
      action = "Overwrite"
      header_action_parameters {
        header_name  = "Cache-Control"
        header_value = "max-age=31536000"
      }
    }
  }

  query_string_caching_behavior = var.query_string_caching_behavior

  tags = var.tags
}