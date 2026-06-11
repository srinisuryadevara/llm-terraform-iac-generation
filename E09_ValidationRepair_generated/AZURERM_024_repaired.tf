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

variable "frontend_ip_configuration_name" {
  type = string
}

variable "frontend_ip_configuration_private_ip_address" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_public_ip" "example" {
  name                = "example-public-ip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Dynamic"
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_lb" "example" {
  name                = var.load_balancer_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"
  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
  }

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
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
  protocol        = "Tcp"
  interval_in_seconds = 5
  number_of_probes = 2
}

output "resource_group_id" {
  value = azurerm_resource_group.example.id
}

output "public_ip_address" {
  value = azurerm_public_ip.example.ip_address
}

output "load_balancer_id" {
  value = azurerm_lb.example.id
}

output "load_balancer_frontend_ip_configuration_id" {
  value = azurerm_lb.example.frontend_ip_configuration[0].id
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.example.id
}

output "health_probe_id" {
  value = azurerm_lb_probe.example.id
}