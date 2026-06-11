provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Location of the resource group"
}

variable "application_gateway_name" {
  type        = string
  description = "Name of the application gateway"
}

variable "waf_policy_name" {
  type        = string
  description = "Name of the WAF policy"
}

variable "backend_pool_name" {
  type        = string
  description = "Name of the backend pool"
}

variable "frontend_ip_configuration_name" {
  type        = string
  description = "Name of the frontend IP configuration"
}

variable "frontend_port_name" {
  type        = string
  description = "Name of the frontend port"
}

variable "http_setting_name" {
  type        = string
  description = "Name of the HTTP setting"
}

variable "listener_name" {
  type        = string
  description = "Name of the listener"
}

variable "rule_name" {
  type        = string
  description = "Name of the rule"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet"
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
    enabled                  = true
    firewall_mode            = "Detection"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    max_request_body_size_kb = 128
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
    subnet_id            = var.subnet_id
    private_ip_address   = "10.0.0.10"
    private_ip_address_allocation = "Static"
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
    http_listener_name         = azurerm_application_gateway.example.http_listener[0].name
    backend_address_pool_name  = azurerm_application_gateway.example.backend_address_pool[0].name
    backend_http_settings_name = azurerm_application_gateway.example.backend_http_settings[0].name
  }
}

resource "azurerm_web_application_firewall_policy" "example" {
  name                = var.waf_policy_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    file_upload_limit_mb        = 100
    max_request_body_size_kb    = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway_waf_policy" "example" {
  application_gateway_id = azurerm_application_gateway.example.id
  waf_policy_id          = azurerm_web_application_firewall_policy.example.id
}