provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "load_balancer_name" {
  type = string
}

variable "backend_pool_name" {
  type = string
}

variable "health_probe_name" {
  type = string
}

variable "health_probe_port" {
  type = number
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_public_ip" "example" {
  name                = "example-public-ip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method = "Dynamic"
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
}

resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = var.backend_pool_name
}

resource "azurerm_lb_probe" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = var.health_probe_name
  port            = var.health_probe_port
  protocol        = "Http"
  request_path    = "/"
}

resource "azurerm_lb_rule" "example" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "example-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "example-frontend-ip"
  backend_address_pool_id         = azurerm_lb_backend_address_pool.example.id
  probe_id                       = azurerm_lb_probe.example.id
}