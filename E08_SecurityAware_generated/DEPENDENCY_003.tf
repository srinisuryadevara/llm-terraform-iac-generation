provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "region" {
  type        = string
  description = "Azure region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "ssh_source_cidr" {
  type        = string
  description = "SSH source CIDR"
}

variable "vnet_cidr" {
  type        = string
  description = "VNet CIDR"
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet CIDR"
}

variable "app_gateway_sku" {
  type        = string
  description = "Application Gateway SKU"
}

variable "app_gateway_tier" {
  type        = string
  description = "Application Gateway tier"
}

variable "app_gateway_capacity" {
  type        = number
  description = "Application Gateway capacity"
}

variable "tls_min_version" {
  type        = string
  description = "Minimum TLS version"
  default     = "1.2"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.region
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.project}-${var.environment}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_subnet" "example" {
  name                 = "${var.project}-${var.environment}-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = [var.subnet_cidr]
}

resource "azurerm_public_ip" "example" {
  name                = "${var.project}-${var.environment}-pip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.project}-${var.environment}-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_network_security_rule" "example" {
  name                        = "${var.project}-${var.environment}-nsg-rule"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = var.ssh_source_cidr
  destination_address_prefix = azurerm_subnet.example.address_prefix
}

resource "azurerm_application_gateway" "example" {
  name                = "${var.project}-${var.environment}-agw"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku {
    name     = var.app_gateway_sku
    tier     = var.app_gateway_tier
    capacity = var.app_gateway_capacity
  }
  tls_policy {
    policy_type = "Predefined"
    policy_name = "TLS_1_2"
  }
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "SSL30"
  }
  min_tls_version = var.tls_min_version
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_application_gateway_ip_configuration" "example" {
  name                         = "${var.project}-${var.environment}-agw-ip-config"
  application_gateway_name    = azurerm_application_gateway.example.name
  resource_group_name         = azurerm_resource_group.example.name
  subnet_id                   = azurerm_subnet.example.id
}

resource "azurerm_application_gateway_frontend_ip_configuration" "example" {
  name                         = "${var.project}-${var.environment}-agw-frontend-ip-config"
  application_gateway_name    = azurerm_application_gateway.example.name
  resource_group_name         = azurerm_resource_group.example.name
  public_ip_address_id        = azurerm_public_ip.example.id
}

resource "azurerm_application_gateway_backend_address_pool" "example" {
  name                = "${var.project}-${var.environment}-agw-backend-pool"
  application_gateway_name = azurerm_application_gateway.example.name
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_application_gateway_backend_http_settings" "example" {
  name                  = "${var.project}-${var.environment}-agw-backend-http-settings"
  application_gateway_name = azurerm_application_gateway.example.name
  resource_group_name = azurerm_resource_group.example.name
  cookie_based_affinity = "Disabled"
  port                  = 80
  protocol              = "Http"
  request_timeout       = 30
}

resource "azurerm_application_gateway_http_listener" "example" {
  name                           = "${var.project}-${var.environment}-agw-http-listener"
  application_gateway_name       = azurerm_application_gateway.example.name
  resource_group_name            = azurerm_resource_group.example.name
  frontend_ip_configuration_name = azurerm_application_gateway_frontend_ip_configuration.example.name
  frontend_port_name             = "http"
  protocol                       = "Http"
}

resource "azurerm_application_gateway_request_routing_rule" "example" {
  name                       = "${var.project}-${var.environment}-agw-routing-rule"
  application_gateway_name   = azurerm_application_gateway.example.name
  resource_group_name        = azurerm_resource_group.example.name
  rule_type                  = "Basic"
  http_listener_name         = azurerm_application_gateway_http_listener.example.name
  backend_address_pool_name  = azurerm_application_gateway_backend_address_pool.example.name
  backend_http_settings_name = azurerm_application_gateway_backend_http_settings.example.name
}