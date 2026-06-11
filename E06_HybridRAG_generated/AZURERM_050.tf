terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.86.0"
    }
  }
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "prefix" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "public_ip_address_id" {
  type = string
}

variable "backend_address" {
  type = string
}

variable "backend_port" {
  type = number
}

variable "waf_policy_mode" {
  type = string
}

variable "waf_policy_rule_set_version" {
  type = string
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_subnet" "app_gateway" {
  name                 = "app-gateway-subnet"
  virtual_network_name = "app-gateway-vnet"
  resource_group_name  = var.resource_group_name
}

data "azurerm_virtual_network" "main" {
  name                = "app-gateway-vnet"
  resource_group_name = var.resource_group_name
}

resource "azurerm_public_ip" "app_gateway" {
  name                = "${var.prefix}-app-gateway-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
}

locals {
  frontend_port_name             = "${var.prefix}-app-gateway-frontend-port"
  frontend_ip_configuration_name = "${var.prefix}-app-gateway-frontend-ip"
  backend_address_pool_name      = "${var.prefix}-app-gateway-backend-pool"
  backend_http_setting_name      = "${var.prefix}-app-gateway-backend-http-setting"
  listener_name                  = "${var.prefix}-app-gateway-listener"
  request_routing_rule_name      = "${var.prefix}-app-gateway-request-routing-rule"
  probe_name                     = "${var.prefix}-app-gateway-probe"
}

resource "azurerm_application_gateway" "main" {
  name                = "${var.prefix}-app-gateway"
  resource_group_name = var.resource_group_name
  location            = var.location

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
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = var.public_ip_address_id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.backend_http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = var.backend_port
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_setting_name
  }

  web_application_firewall_configuration {
    enabled                  = true
    firewall_mode            = var.waf_policy_mode
    rule_set_version         = var.waf_policy_rule_set_version
    file_upload_limit_mb     = 100
    request_body_limit_kb    = 128
  }
}

resource "azurerm_application_gateway_backend_address_pool" "main" {
  name            = local.backend_address_pool_name
  application_gateway_name = azurerm_application_gateway.main.name
  resource_group_name = var.resource_group_name

  ip_addresses = [
    var.backend_address
  ]
}