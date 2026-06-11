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

variable "waf_policy_id" {
  type = string
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
    firewall_mode            = "Detection"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    request_body_limit_kb    = 128
    max_file_upload_limit_mb = 500
  }

  backend_http_settings {
    name                  = "${local.backend_http_setting_name}-https"
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
  }

  https_listener {
    name                           = "${local.listener_name}-https"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "${local.frontend_port_name}-https"
    protocol                       = "Https"
    ssl_certificate_name           = "appgw-ssl-cert"
  }

  ssl_certificate {
    name                = "appgw-ssl-cert"
    data                = file("~/.ssh/appgw-ssl-cert.pfx")
    password            = "password"
    key_vault_secret_id = var.waf_policy_id
  }

  frontend_port {
    name = "${local.frontend_port_name}-https"
    port = 443
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-https"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}-https"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = "${local.backend_http_setting_name}-https"
  }

  backend {
    ip_address = var.backend_address
    host_header = var.backend_address
  }
}