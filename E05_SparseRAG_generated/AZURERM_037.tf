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

variable "cdn_custom_domain_name" {
  type = string
}

variable "dns_a_record_name" {
  type = string
}

variable "key_vault_certificate_id" {
  type = string
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_cdn_profile" "main" {
  name                = var.cdn_profile_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard_Microsoft"
}

locals {
  host_name = regex("^https://(.*)/$", azurerm_storage_account.main.primary_web_endpoint)[0]
}

resource "azurerm_cdn_endpoint" "main" {
  name                = var.cdn_endpoint_name
  profile_name        = azurerm_cdn_profile.main.name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  origin {
    name      = "origin1"
    host_name = local.host_name
  }
  origin_host_header = local.host_name

  delivery_rule {
    name  = "httpsredirect"
    order = 1

    request_scheme_condition {
      match_values = [
        "HTTP",
      ]
      negate_condition = false
      operator         = "Equal"
    }

    url_redirect_action {
      protocol      = "Https"
      redirect_type = "PermanentRedirect"
    }
  }

  lifecycle {
    ignore_changes = [origin, is_compression_enabled]
  }
}

resource "azurerm_cdn_endpoint_custom_domain" "main" {
  cdn_endpoint_id = azurerm_cdn_endpoint.main.id
  name            = var.cdn_custom_domain_name
  host_name       = var.cdn_custom_domain_name
  user_managed_https {
    key_vault_certificate_id = var.key_vault_certificate_id
  }
}