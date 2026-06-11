provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "application_gateway_name" {
  type        = string
  description = "The name of the application gateway"
}

variable "waf_policy_name" {
  type        = string
  description = "The name of the WAF policy"
}

variable "backend_pool_name" {
  type        = string
  description = "The name of the backend pool"
}

variable "frontend_ip_configuration_name" {
  type        = string
  description = "The name of the frontend IP configuration"
}

variable "http_listener_name" {
  type        = string
  description = "The name of the HTTP listener"
}

variable "request_routing_rule_name" {
  type        = string
  description = "The name of the request routing rule"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet"
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
  autoscale_configuration {
    min_capacity = 0
    max_capacity = 10
  }
  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    subnet_id            = var.subnet_id
    private_ip_address   = "10.0.0.10"
    private_ip_address_allocation = "Static"
  }
  frontend_port {
    name = "http"
    port = 80
  }
  http_listener {
    name                           = var.http_listener_name
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = "http"
    protocol                       = "Http"
  }
  request_routing_rule {
    name                       = var.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = var.http_listener_name
    backend_address_pool_name  = var.backend_pool_name
    backend_http_settings_name = "http"
  }
  backend_address_pool {
    name = var.backend_pool_name
  }
  backend_http_settings {
    name                  = "http"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }
  waf_configuration {
    enabled                  = true
    file_upload_limit_mb     = 100
    max_request_body_size_kb = 128
    mode                     = "Prevention"
    rule_set_version         = "3.2"
  }
}

resource "azurerm_web_application_firewall_policy" "example" {
  name                = var.waf_policy_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  mode                = "Prevention"
  policy_settings {
    file_upload_limit_mb = 100
    max_request_body_size_kb = 128
  }
  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway_web_application_firewall_policy_association" "example" {
  application_gateway_id = azurerm_application_gateway.example.id
  web_application_firewall_policy_id = azurerm_web_application_firewall_policy.example.id
}