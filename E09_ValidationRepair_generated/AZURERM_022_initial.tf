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

variable "health_probe_protocol" {
  type = string
}

variable "health_probe_interval" {
  type = number
}

variable "health_probe_unhealthy_threshold" {
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
  allocation_method   = "Dynamic"
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
  name            = var.backend_pool_name
  loadbalancer_id = azurerm_lb.example.id
}

resource "azurerm_lb_probe" "example" {
  name                = var.health_probe_name
  loadbalancer_id     = azurerm_lb.example.id
  protocol            = var.health_probe_protocol
  port                = var.health_probe_port
  interval_in_seconds = var.health_probe_interval
  number_of_probes    = var.health_probe_unhealthy_threshold
}