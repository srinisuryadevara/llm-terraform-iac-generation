terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "azurerm" {
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

variable "app_gateway_name" {
  type        = string
  description = "The name of the application gateway"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet"
}

variable "public_ip_address_id" {
  type        = string
  description = "The ID of the public IP address"
}

variable "backend_address_pool_name" {
  type        = string
  description = "The name of the backend address pool"
}

variable "http_setting_name" {
  type        = string
  description = "The name of the HTTP setting"
}

variable "listener_name" {
  type        = string
  description = "The name of the HTTP listener"
}

variable "frontend_ip_configuration_name" {
  type        = string
  description = "The name of the frontend IP configuration"
}

variable "frontend_port_name" {
  type        = string
  description = "The name of the frontend port"
}

variable "request_routing_rule_name" {
  type        = string
  description = "The name of the request routing rule"
}

variable "waf_policy_name" {
  type        = string
  description = "The name of the WAF policy"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_public_ip" "example" {
  name                = "example-public-ip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-virtual-network"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_application_gateway" "example" {
  name                = var.app_gateway_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.example.id
  }

  frontend_port {
    name = var.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }

  backend_address_pool {
    name = var.backend_address_pool_name
  }

  backend_http_settings {
    name                  = var.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = var.listener_name
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = var.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = var.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = var.listener_name
    backend_address_pool_name  = var.backend_address_pool_name
    backend_http_settings_name = var.http_setting_name
  }

  web_application_firewall_configuration {
    enabled                  = true
    firewall_mode            = "Detection"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    request_body_limit_kb    = 128
    max_file_upload_limit_mb = 500
  }
}

resource "azurerm_web_application_firewall_policy" "example" {
  name                = var.waf_policy_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_mb        = 100
    max_file_upload_limit_mb    = 500
    max_request_body_size_kb    = 128
    file_upload_rules {
      file_types = ["pdf", "docx"]
      size_limit_mb = 10
    }
  }

  custom_rules {
    name      = "example-rule"
    priority  = 1
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "QueryString"
      }

      operator           = "Contains"
      negation_condition = false
      values             = ["example"]
    }

    action = "Block"
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"

      rule_group_override {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
        rules {
          rule_id = "920300"
          enabled = false
        }
      }
    }
  }
}

resource "azurerm_application_gateway_web_application_firewall_policy" "example" {
  application_gateway_id = azurerm_application_gateway.example.id
  web_application_firewall_policy_id = azurerm_web_application_firewall_policy.example.id
}