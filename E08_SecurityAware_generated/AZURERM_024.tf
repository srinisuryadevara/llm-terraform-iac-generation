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

variable "allowed_cidr" {
  type        = string
  description = "Allowed CIDR for load balancer"
}

variable "load_balancer_name" {
  type        = string
  description = "Load balancer name"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "backend_pool_name" {
  type        = string
  description = "Backend pool name"
}

variable "health_probe_name" {
  type        = string
  description = "Health probe name"
}

variable "health_probe_port" {
  type        = number
  description = "Health probe port"
}

variable "health_probe_protocol" {
  type        = string
  description = "Health probe protocol"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.region
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_public_ip" "example" {
  name                = "example-public-ip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_lb" "example" {
  name                = var.load_balancer_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "example-frontend-ip"
    public_ip_address_id = azurerm_public_ip.example.id
  }
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_lb_backend_address_pool" "example" {
  name            = var.backend_pool_name
  loadbalancer_id = azurerm_lb.example.id
}

resource "azurerm_lb_probe" "example" {
  name                = var.health_probe_name
  loadbalancer_id     = azurerm_lb.example.id
  port                = var.health_probe_port
  protocol            = var.health_probe_protocol
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  security_rule {
    name                       = "example-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.allowed_cidr
    destination_address_prefix = "*"
  }
  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "azurerm_network_security_rule" "example" {
  name                        = "example-rule-2"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = var.allowed_cidr
  destination_address_prefix = "*"
  resource_group_name        = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}