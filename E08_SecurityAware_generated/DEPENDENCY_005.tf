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

variable "admin_username" {
  type        = string
  description = "Admin username"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Admin password"
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
  address_space       = ["10.0.0.0/16"]
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
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "${var.project}-${var.environment}-pip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_application_gateway" "example" {
  name                = "${var.project}-${var.environment}-agw"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }
  min_capacity = 1
  max_capacity = 10
  tags = {
    environment = var.environment
    project     = var.project
  }
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "TLS_1_2"
  }
  ssl_certificate {
    name = "example-cert"
    data = file("~/.ssh/example-cert.pfx")
    password = var.admin_password
  }
  frontend_ip_configuration {
    name                 = "${var.project}-${var.environment}-feip"
    public_ip_address_id = azurerm_public_ip.example.id
  }
  frontend_port {
    name = "${var.project}-${var.environment}-feport"
    port = 443
  }
  backend_address_pool {
    name = "${var.project}-${var.environment}-beap"
  }
  backend_http_settings {
    name                  = "${var.project}-${var.environment}-behs"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
  }
  http_listener {
    name                           = "${var.project}-${var.environment}-httpl"
    frontend_ip_configuration_name = azurerm_application_gateway.example.frontend_ip_configuration[0].name
    frontend_port_name             = azurerm_application_gateway.example.frontend_port[0].name
    protocol                       = "Https"
    ssl_certificate_name           = azurerm_application_gateway.example.ssl_certificate[0].name
    host_names                     = ["example.com"]
  }
  request_routing_rule {
    name                       = "${var.project}-${var.environment}-r3"
    rule_type                  = "Basic"
    http_listener_name         = azurerm_application_gateway.example.http_listener[0].name
    backend_address_pool_name  = azurerm_application_gateway.example.backend_address_pool[0].name
    backend_http_settings_name = azurerm_application_gateway.example.backend_http_settings[0].name
  }
  depends_on = [
    azurerm_public_ip.example,
    azurerm_virtual_network.example,
    azurerm_subnet.example
  ]
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.project}-${var.environment}-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = var.environment
    project     = var.project
  }
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_source_cidr
    destination_address_prefix = azurerm_subnet.example.address_prefixes[0]
  }
}

resource "azurerm_network_security_rule" "example" {
  name                        = "HTTPS"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range      = "443"
  source_address_prefix      = var.ssh_source_cidr
  destination_address_prefix = azurerm_subnet.example.address_prefixes[0]
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}