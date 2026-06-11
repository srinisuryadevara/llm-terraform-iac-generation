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

variable "waf_policy_name" {
  type = string
}

variable "backend_pool_name" {
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
  autoscale_configuration {
    min_capacity = 0
    max_capacity = 10
  }
}

resource "azurerm_web_application_firewall_policy" "example" {
  name                = var.waf_policy_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  mode                = "Prevention"
  policy_settings {
    enabled = true
  }
  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway_waf_configuration" "example" {
  enabled                  = true
  firewall_mode            = "Prevention"
  rule_set_type            = "OWASP"
  rule_set_version         = "3.2"
  file_upload_limit_mb     = 100
  max_request_body_size_kb = 128
}

resource "azurerm_application_gateway_backend_address_pool" "example" {
  name            = var.backend_pool_name
  application_gateway_name = azurerm_application_gateway.example.name
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_application_gateway_backend_http_settings" "example" {
  name                                = "http-settings"
  application_gateway_name           = azurerm_application_gateway.example.name
  resource_group_name                 = azurerm_resource_group.example.name
  cookie_based_affinity              = "Disabled"
  port                                = 80
  protocol                            = "Http"
  request_timeout                     = 60
}

resource "azurerm_application_gateway_request_routing_rule" "example" {
  name                       = "routing-rule"
  application_gateway_name    = azurerm_application_gateway.example.name
  resource_group_name         = azurerm_resource_group.example.name
  rule_type                   = "Basic"
  http_listener_name         = "http-listener"
  backend_address_pool_name   = azurerm_application_gateway_backend_address_pool.example.name
  backend_http_settings_name = azurerm_application_gateway_backend_http_settings.example.name
}

resource "azurerm_application_gateway_http_listener" "example" {
  name                           = "http-listener"
  application_gateway_name       = azurerm_application_gateway.example.name
  resource_group_name             = azurerm_resource_group.example.name
  frontend_ip_configuration_name = "frontend-ip-config"
  frontend_port_name             = "frontend-port"
  protocol                       = "Http"
}

resource "azurerm_application_gateway_frontend_ip_configuration" "example" {
  name                          = "frontend-ip-config"
  application_gateway_name      = azurerm_application_gateway.example.name
  resource_group_name            = azurerm_resource_group.example.name
  subnet_id                    = azurerm_subnet.example.id
}

resource "azurerm_application_gateway_frontend_port" "example" {
  name                          = "frontend-port"
  application_gateway_name       = azurerm_application_gateway.example.name
  resource_group_name             = azurerm_resource_group.example.name
  port                            = 80
}

resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}