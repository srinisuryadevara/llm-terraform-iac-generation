provider "azurerm" {
  version = "3.34.0"
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

variable "rule_set_name" {
  type = string
}

variable "subnet_id" {
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

  waf_configuration {
    enabled                  = true
    firewall_mode            = "Detection"
    rule_set_type             = "OWASP"
    rule_set_version          = "3.1"
    file_upload_limit_mb     = 100
    request_body_limit_kb     = 128
    max_request_body_size_kb = 128
  }

  gateway_ip_configuration {
    name = "gateway-ip-configuration"
  }

  frontend_ip_configuration {
    name = var.frontend_ip_configuration_name
  }

  frontend_port {
    name = var.frontend_port_name
    port = 80
  }

  backend_address_pool {
    name = var.backend_pool_name
  }

  backend_http_settings {
    name                  = var.http_setting_name
    cookie_based_affinity = "Disabled"
    port                   = 80
    protocol               = "Http"
    request_timeout         = 60
  }

  http_listener {
    name                           = var.listener_name
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = var.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "request-routing-rule"
    rule_type                  = "Basic"
    http_listener_name          = var.listener_name
    backend_address_pool_name  = var.backend_pool_name
    backend_http_settings_name = var.http_setting_name
  }
}

resource "azurerm_web_application_firewall_policy" "example" {
  name                = var.waf_policy_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  mode                = "Prevention"

  policy_settings {
    enabled                     = true
    mode                         = "Prevention"
    request_body_size_limit_kb   = 128
    file_upload_limit_mb        = 100
    max_request_body_size_kb    = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.1"
    }
  }
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = "example-virtual-network"
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  ip_configuration {
    name                          = "example-ip-configuration"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}