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

variable "frontend_ip_configuration_private_ip_address" {
  type = string
}

variable "frontend_ip_configuration_private_ip_address_allocation" {
  type = string
}

variable "frontend_ip_configuration_private_ip_address_version" {
  type = string
}

variable "frontend_ip_configuration_subnet_id" {
  type = string
}

variable "frontend_ip_configuration_zone" {
  type = string
}

variable "backend_address_pool_name" {
  type = string
}

variable "probe_name" {
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

variable "probe_request_path" {
  type = string
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

variable "load_balancing_rule_idle_timeout_in_minutes" {
  type = number
}

variable "load_balancing_rule_enable_floating_ip" {
  type = bool
}

variable "load_balancing_rule_load_distribution" {
  type = string
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_public_ip" "example" {
  name                = "public-ip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "example" {
  name                = var.load_balancer_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

resource "azurerm_lb_backend_address_pool" "example" {
  name            = var.backend_pool_name
  loadbalancer_id = azurerm_lb.example.id
}

resource "azurerm_lb_probe" "example" {
  name            = var.probe_name
  loadbalancer_id = azurerm_lb.example.id
  protocol        = var.probe_protocol
  port            = var.probe_port
  interval_in_seconds = var.probe_interval_in_seconds
  number_of_probes    = var.probe_unhealthy_threshold
  request_path        = var.probe_request_path
}

resource "azurerm_lb_rule" "example" {
  name                           = var.load_balancing_rule_name
  loadbalancer_id                = azurerm_lb.example.id
  protocol                       = var.load_balancing_rule_protocol
  frontend_port                  = var.load_balancing_rule_frontend_port
  backend_port                   = var.load_balancing_rule_backend_port
  frontend_ip_configuration_name = var.frontend_ip_configuration_name
  backend_address_pool_name      = var.backend_address_pool_name
  probe_id                       = azurerm_lb_probe.example.id
  idle_timeout_in_minutes        = var.load_balancing_rule_idle_timeout_in_minutes
  enable_floating_ip             = var.load_balancing_rule_enable_floating_ip
  load_distribution              = var.load_balancing_rule_load_distribution
}