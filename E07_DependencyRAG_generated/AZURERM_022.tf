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

variable "primary_web_application" {
  type = object({
    default_site_hostname = string
  })
}

variable "secondary_web_application" {
  type = object({
    default_site_hostname = string
  })
}

variable "app_name" {
  type = string
}

variable "shared_name" {
  type = string
}

variable "rg_name" {
  type = string
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location_for_rg
}

resource "azurerm_public_ip" "pip-lbe-test-eastus-001" {
  name                = "pip-lbe-test-eastus-001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = "${var.app_name}-lb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${var.app_name}-frontend"
    public_ip_address_id = azurerm_public_ip.pip-lbe-test-eastus-001.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "${var.app_name}-backend-pool"
}

resource "azurerm_lb_probe" "health_probe" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "${var.app_name}-health-probe"
  port            = 80
  protocol        = "Http"
  request_path    = "/"
}

resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                            = "${var.app_name}-lb-rule"
  protocol                        = "Http"
  frontend_port                   = 80
  backend_port                    = 80
  frontend_ip_configuration_name  = "${var.app_name}-frontend"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                        = azurerm_lb_probe.health_probe.id
}

resource "azurerm_lb_backend_address_pool_address" "primary_address" {
  name                    = "${var.app_name}-primary-address"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  ip_address              = var.primary_web_application.default_site_hostname
  virtual_network_id      = null
}

resource "azurerm_lb_backend_address_pool_address" "secondary_address" {
  name                    = "${var.app_name}-secondary-address"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  ip_address              = var.secondary_web_application.default_site_hostname
  virtual_network_id      = null
}