variable "prefix" {
  type        = string
  description = "Prefix for resource names"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Location of the resources"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet for the Application Gateway"
}

variable "public_ip_address_id" {
  type        = string
  description = "ID of the public IP address for the Application Gateway"
}

variable "waf_policy_id" {
  type        = string
  description = "ID of the WAF policy"
}

variable "backend_address_pool_addresses" {
  type        = list(string)
  description = "List of IP addresses or FQDNs for the backend pool"
}

locals {
  frontend_port_name             = "${var.prefix}-app-gateway-frontend-port"
  frontend_ip_configuration_name = "${var.prefix}-app-gateway-frontend-ip"
  backend_address_pool_name      = "${var.prefix}-app-gateway-backend-pool"
  backend_http_setting_name      = "${var.prefix}-app-gateway-backend-http-setting"
  listener_name                  = "${var.prefix}-app-gateway-listener"
  request_routing_rule_name      = "${var.prefix}-app-gateway-request-routing-rule"
}

resource "azurerm_public_ip" "app_gateway" {
  name                = "${var.prefix}-app-gateway-public-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Dynamic"
}

resource "azurerm_application_gateway" "main" {
  name                = "${var.prefix}-app-gateway"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
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
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.backend_http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
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
    firewall_mode            = "Detection"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    request_body_limit_kb    = 128
    max_file_upload_limit_mb = 500
  }
}

resource "azurerm_application_gateway_backend_address_pool_address" "main" {
  count                   = length(var.backend_address_pool_addresses)
  name                    = "${local.backend_address_pool_name}-${count.index}"
  application_gateway_name = azurerm_application_gateway.main.name
  resource_group_name     = var.resource_group_name
  ip_address              = var.backend_address_pool_addresses[count.index]
}