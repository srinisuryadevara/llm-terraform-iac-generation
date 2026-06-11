provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "application_gateway_name" {
  type = string
}

variable "backend_pool_name" {
  type = string
}

variable "frontend_ip_configuration_name" {
  type = string
}

variable "frontend_port_name" {
  type = string
}

variable "http_setting_name" {
  type = string
}

variable "listener_name" {
  type = string
}

variable "rule_name" {
  type = string
}

variable "waf_policy_name" {
  type = string
}

variable "waf_policy_mode" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_application_gateway" "example" {
  name                = var.application_gateway_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  waf_configuration {
    enabled = true
    rule_set {
      type = "OWASP"
      version = "3.1"
    }
    file_upload_limit_mb = 100
  }

  backend_address_pool {
    name = var.backend_pool_name
  }

  backend_http_settings {
    name                  = var.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }

  frontend_port {
    name = var.frontend_port_name
    port = 80
  }

  http_listener {
    name                           = var.listener_name
    frontend_ip_configuration_name = azurerm_application_gateway.example.frontend_ip_configuration[0].name
    frontend_port_name             = azurerm_application_gateway.example.frontend_port[0].name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = var.rule_name
    rule_type                  = "Basic"
    http_listener_name          = azurerm_application_gateway.example.http_listener[0].name
    backend_address_pool_name   = azurerm_application_gateway.example.backend_address_pool[0].name
    backend_http_settings_name  = azurerm_application_gateway.example.backend_http_settings[0].name
  }
}

resource "azurerm_public_ip" "example" {
  name                = "example-public-ip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method  = "Dynamic"
}

resource "azurerm_waf_policy" "example" {
  name                = var.waf_policy_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  mode               = var.waf_policy_mode

  policy_settings {
    file_upload_limit_mb = 100
  }

  rule_group {
    rule_group_name = "OWASP"
    rule_group_type = "OWASP"
  }
}