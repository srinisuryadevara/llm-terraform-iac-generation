terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.86.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location_for_rg" {
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

variable "frontend_ip_configuration_name" {
  type = string
}

variable "primary_web_application_default_site_hostname" {
  type = string
}

variable "secondary_web_application_default_site_hostname" {
  type = string
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location_for_rg
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.load_balancer_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = var.load_balancer_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = var.backend_pool_name
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_probe" "health_probe" {
  name            = var.health_probe_name
  loadbalancer_id = azurerm_lb.lb.id
  port            = 80
}

resource "azurerm_lb_rule" "rule" {
  name                           = "rule-${var.load_balancer_name}"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend!_ip_configuration_name = var.frontend_ip_configuration_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.health_probe.id
}

resource "azurerm_lb_backend_address_pool_address" "primary_address" {
  name                    = "primary-address"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  ip_address              = var.primary_web_application_default_site_hostname
  virtual_network_id      = null
}

resource "azurerm_lb_backend_address_pool_address" "secondary_address" {
  name                    = "secondary-address"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  ip_address              = var.secondary_web_application_default_site_hostname
  virtual_network_id      = null
}