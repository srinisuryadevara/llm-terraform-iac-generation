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

variable "backend_pool_name" {
  type        = string
  description = "Backend pool name"
}

variable "waf_policy_mode" {
  type        = string
  description = "WAF policy mode"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.region
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.project}-${var.environment}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_subnet" "example" {
  name                 = "${var.project}-${var.environment}-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "${var.project}-${var.environment}-pip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_application_gateway" "example" {
  name                = "${var.project}-${var.environment}-agw"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_application_gateway_waf_configuration" "example" {
  enabled                  = true
  file_upload_limit_mb     = 100
  max_request_body_size_kb = 128
  mode                      = var.waf_policy_mode
  rule_set {
    type              = "OWASP"
    version           = "3.1"
    rule_group_override {
      rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
      rules {
        rule_id = "920300"
        enabled = false
      }
    }
  }
}

resource "azurerm_application_gateway_backend_address_pool" "example" {
  name            = var.backend_pool_name
  application_gateway_name = azurerm_application_gateway.example.name
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_application_gateway_backend_http_settings" "example" {
  name                  = "${var.project}-${var.environment}-http-settings"
  resource_group_name = azurerm_resource_group.example.name
  application_gateway_name = azurerm_application_gateway.example.name
  cookie_based_affinity = "Disabled"
  port                  = 80
  protocol             = "Http"
  request_timeout      = 30
}

resource "azurerm_application_gateway_http_listener" "example" {
  name                           = "${var.project}-${var.environment}-http-listener"
  application_gateway_name = azurerm_application_gateway.example.name
  resource_group_name = azurerm_resource_group.example.name
  frontend_ip_configuration_name = "appGwPublic"
  frontend_port_name             = "http"
  protocol                       = "Http"
}

resource "azurerm_application_gateway_request_routing_rule" "example" {
  name                       = "${var.project}-${var.environment}-routing-rule"
  resource_group_name = azurerm_resource_group.example.name
  application_gateway_name = azurerm_application_gateway.example.name
  rule_type                 = "Basic"
  http_listener_name        = azurerm_application_gateway_http_listener.example.name
  backend_address_pool_name = azurerm_application_gateway_backend_address_pool.example.name
  backend_http_settings_name = azurerm_application_gateway_backend_http_settings.example.name
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.project}-${var.environment}-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_network_security_rule" "example" {
  name                        = "${var.project}-${var.environment}-nsg-rule"
  resource_group_name = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = var.ssh_source_cidr
  destination_address_prefix = "*"
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}