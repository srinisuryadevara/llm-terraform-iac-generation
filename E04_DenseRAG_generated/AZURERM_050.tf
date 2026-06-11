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
  type = string
}

variable "location" {
  type = string
}

variable "app_gateway_name" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "sku_tier" {
  type = string
}

variable "sku_capacity" {
  type = number
}

variable "frontend_ip_configuration_name" {
  type = string
}

variable "public_ip_address_id" {
  type = string
}

variable "backend_address_pool_name" {
  type = string
}

variable "http_setting_name" {
  type = string
}

variable "listener_name" {
  type = string
}

variable "frontend_port_name" {
  type = string
}

variable "frontend_port" {
  type = number
}

variable "request_routing_rule_name" {
  type = string
}

variable "waf_policy_name" {
  type = string
}

variable "waf_policy_mode" {
  type = string
}

variable "waf_policy_rule_set_version" {
  type = string
}

resource "azurerm_application_gateway" "network" {
  name                = var.app_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.sku_capacity
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = "your subnet id"
  }

  frontend_port {
    name = var.frontend_port_name
    port = var.frontend_port
  }

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = var.public_ip_address_id
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
    firewall_mode            = var.waf_policy_mode
    rule_set_version         = var.waf_policy_rule_set_version
    rule_set_type            = "OWASP"
    disabled_rule_group      = []
    file_upload_limit_mb     = 100
    max_request_body_size_kb = 128
  }
}

resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = var.waf_policy_name
  resource_group_name = var.resource_group_name
  location            = var.location
  mode                = var.waf_policy_mode

  policy_settings {
    enabled                     = true
    file_upload_limit_mb        = 100
    max_request_body_size_kb    = 128
    request_body_check          = true
    max_request_header_length   = 8
    max_request_query_string_length = 2048
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = var.waf_policy_rule_set_version
    }
  }
}