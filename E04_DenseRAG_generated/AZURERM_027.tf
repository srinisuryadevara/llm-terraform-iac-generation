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
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Location of the resource group"
}

variable "app_gateway_name" {
  type        = string
  description = "Name of the Application Gateway"
}

variable "waf_policy_name" {
  type        = string
  description = "Name of the WAF policy"
}

variable "backend_address_pool_name" {
  type        = string
  description = "Name of the backend address pool"
}

variable "frontend_ip_configuration_name" {
  type        = string
  description = "Name of the frontend IP configuration"
}

variable "frontend_port_name" {
  type        = string
  description = "Name of the frontend port"
}

variable "http_listener_name" {
  type        = string
  description = "Name of the HTTP listener"
}

variable "request_routing_rule_name" {
  type        = string
  description = "Name of the request routing rule"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet"
}

variable "public_ip_address_id" {
  type        = string
  description = "ID of the public IP address"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
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
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = var.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = var.public_ip_address_id
  }

  backend_address_pool {
    name = var.backend_address_pool_name
  }

  backend_http_settings {
    name                  = "http-setting"
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = var.http_listener_name
    frontend_ip_configuration_name = var.frontend_ip_configuration_name
    frontend_port_name             = var.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = var.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = var.http_listener_name
    backend_address_pool_name  = var.backend_address_pool_name
    backend_http_settings_name = "http-setting"
  }

  web_application_firewall_configuration {
    enabled                  = true
    firewall_mode            = "Detection"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    max_file_upload_limit_mb = 500
  }
}

resource "azurerm_web_application_firewall_policy" "example" {
  name                = var.waf_policy_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  mode                = "Detection"

  policy_settings {
    enabled                     = true
    mode                        = "Detection"
    file_upload_limit_mb        = 100
    max_file_upload_limit_mb    = 500
    request_body_check          = true
    file_upload_rules           = []
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway_web_application_firewall_policy" "example" {
  application_gateway_id = azurerm_application_gateway.example.id
  web_application_firewall_policy_id = azurerm_web_application_firewall_policy.example.id
}