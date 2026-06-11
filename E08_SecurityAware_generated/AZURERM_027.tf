provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "application_gateway_name" {
  type        = string
  description = "Application gateway name"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for application gateway"
}

variable "waf_policy_name" {
  type        = string
  description = "WAF policy name"
}

variable "backend_pool_name" {
  type        = string
  description = "Backend pool name"
}

variable "frontend_ip_configuration_name" {
  type        = string
  description = "Frontend IP configuration name"
}

variable "http_listener_name" {
  type        = string
  description = "HTTP listener name"
}

variable "http_setting_name" {
  type        = string
  description = "HTTP setting name"
}

variable "request_routing_rule_name" {
  type        = string
  description = "Request routing rule name"
}

variable "tags" {
  type        = map(string)
  description = "Tags for resources"
}

resource "azurerm_application_gateway" "example" {
  name                = var.application_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

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
    file_upload_limit_mb     = 100
    firewall_mode            = "Detection"
    max_request_body_size_kb = 128
    rule_set_version         = "3.2"
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "TLS_1_2"
  }

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_port {
    name = "https"
    port = 443
  }

  backend_address_pool {
    name = var.backend_pool_name
  }

  backend_http_settings {
    name                  = var.http_setting_name
    cookie_based_affinity = "Disabled"
    port                    = 80
    protocol               = "Http"
    request_timeout        = 60
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
    backend_http_settings_name = var.http_setting_name
  }

  ssl_certificate {
    name     = "example"
    data     = file("~/.ssh/example.pfx")
    password = var.ssl_certificate_password
  }
}

variable "ssl_certificate_password" {
  type        = string
  sensitive   = true
  description = "SSL certificate password"
}

resource "azurerm_public_ip" "example" {
  name                = "example"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Dynamic"
  tags                = var.tags
}

resource "azurerm_subnet" "example" {
  name           = "example"
  resource_group_name = var.resource_group_name
  virtual_network_name = "example"
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "example" {
  name                = "example"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_cidr
    destination_address_prefix = "*"
  }
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "Allowed SSH CIDR"
}