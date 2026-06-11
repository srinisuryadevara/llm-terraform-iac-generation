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

variable "sku_name" {
  type        = string
  description = "The SKU name of the application gateway"
}

variable "capacity" {
  type        = number
  description = "The capacity of the application gateway"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the subnet"
}

variable "frontend_ip_configuration_name" {
  type        = string
  description = "The name of the frontend IP configuration"
}

variable "public_ip_address_id" {
  type        = string
  description = "The ID of the public IP address"
}

variable "backend_address_pool_name" {
  type        = string
  description = "The name of the backend address pool"
}

variable "http_listener_name" {
  type        = string
  description = "The name of the HTTP listener"
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

variable "waf_policy_mode" {
  type        = string
  description = "The mode of the WAF policy"
}

variable "waf_policy_rule_set_version" {
  type        = string
  description = "The rule set version of the WAF policy"
}

resource "azurerm_application_gateway" "example" {
  name                = var.app_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = var.sku_name
    tier     = "Standard"
    capacity = var.capacity
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
    firewall_mode            = var.waf_policy_mode
    rule_set_version         = var.waf_policy_rule_set_version
    file_upload_limit_mb     = 100
    max_request_body_size_kb = 128
  }
}

resource "azurerm_web_application_firewall_policy" "example" {
  name                = var.waf_policy_name
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = var.waf_policy_mode
    request_body_check          = true
    file_upload_limit_mb        = 100
    max_request_body_size_kb    = 128
    max_file_upload_size_mb     = 100
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}