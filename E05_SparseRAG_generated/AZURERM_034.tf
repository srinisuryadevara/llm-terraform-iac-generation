terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.86.0"
    }
  }
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

variable "frontend_ip_configuration_name" {
  type = string
}

variable "frontend_ip_address" {
  type = string
}

variable "backend_address_pool_name" {
  type = string
}

variable "probe_protocol" {
  type = string
}

variable "probe_port" {
  type = number
}

variable "probe_interval_in_seconds" {
  type = number
}

variable "probe_unhealthy_threshold" {
  type = number
}

variable "load_balancing_rule_name" {
  type = string
}

variable "load_balancing_rule_protocol" {
  type = string
}

variable "load_balancing_rule_frontend_port" {
  type = number
}

variable "load_balancing_rule_backend_port" {
  type = number
}

variable "idle_timeout_in_minutes" {
  type = number
}

variable "enable_tcp_reset" {
  type = bool
}

variable "enable_floating_ip" {
  type = bool
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "azurerm_public_ip" "main" {
  name                = var.load_balancer_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
}

resource "azurerm_lb" "main" {
  name                = var.load_balancer_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = var.backend_address_pool_name
}

resource "azurerm_lb_probe" "main" {
  loadbalancer_id = azurerm_lb.main.id
  name            = var.health_probe_name
  protocol        = var.probe_protocol
  port            = var.probe_port
  interval_in_seconds = var.probe_interval_in_seconds
  number_of_probes    = var.probe_unhealthy_threshold
}

resource "azurerm_lb_rule" "main" {
  loadbalancer_id                = azurerm_lb.main.id
  name                           = var.load_balancing_rule_name
  protocol                       = var.load_balancing_rule_protocol
  frontend_port                  = var.load_balancing_rule_frontend_port
  backend_port                   = var.load_balancing_rule_backend_port
  frontend_ip_configuration_name = var.frontend_ip_configuration_name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.main.id
  probe_id                       = azurerm_lb_probe.main.id
  idle_timeout_in_minutes        = var.idle_timeout_in_minutes
  enable_tcp_reset               = var.enable_tcp_reset
  enable_floating_ip             = var.enable_floating_ip
}