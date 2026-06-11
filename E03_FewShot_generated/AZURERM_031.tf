provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "load_balancer_name" {
  type        = string
  description = "The name of the load balancer"
}

variable "backend_pool_name" {
  type        = string
  description = "The name of the backend pool"
}

variable "health_probe_name" {
  type        = string
  description = "The name of the health probe"
}

variable "health_probe_port" {
  type        = number
  description = "The port of the health probe"
}

variable "health_probe_protocol" {
  type        = string
  description = "The protocol of the health probe"
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
  port                = var.health_probe_port
  protocol            = var.health_probe_protocol
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

output "load_balancer_id" {
  value = azurerm_lb.example.id
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.example.id
}

output "health_probe_id" {
  value = azurerm_lb_probe.example.id
}