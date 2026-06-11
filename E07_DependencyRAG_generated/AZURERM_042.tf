terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.71.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vmss_name" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type = string
  sensitive = true
}

variable "instance_count" {
  type = number
}

variable "sku" {
  type = string
}

variable "capacity" {
  type = number
}

variable "scale_rule_name" {
  type = string
}

variable "scale_rule_operator" {
  type = string
}

variable "scale_rule_metric_name" {
  type = string
}

variable "scale_rule_metric_namespace" {
  type = string
}

variable "scale_rule_metric_aggregation" {
  type = string
}

variable "scale_rule_metric_operator" {
  type = string
}

variable "scale_rule_metric_threshold" {
  type = number
}

variable "scale_rule_scale_action_direction" {
  type = string
}

variable "scale_rule_scale_action_type" {
  type = string
}

variable "scale_rule_scale_action_value" {
  type = number
}

variable "scale_rule_scale_action_cooldown" {
  type = number
}

resource "azurerm_resource_group" "example" {
  name = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "example-vnet" {
  name = "example-vnet"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example-subnet" {
  name = "example-subnet"
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "example-nsg" {
  name = "example-nsg"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
}

resource "azurerm_network_security_rule" "example-nsg-rule" {
  name = "example-nsg-rule"
  resource_group_name = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example-nsg.name
  priority = 100
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "22"
  source_address_prefix = "*"
  destination_address_prefix = "*"
}

resource "azurerm_virtual_machine_scale_set" "example-vmss" {
  name = var.vmss_name
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  sku {
    name = var.sku
    tier = "Standard"
    capacity = var.capacity
  }
  os_profile {
    computer_name_prefix = "example-vm"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  network_profile {
    name = "example-np"
    primary = true
    network_interface {
      name = "example-nic"
      primary = true
      ip_configuration {
        name = "example-ip"
        primary = true
        subnet_id = azurerm_subnet.example-subnet.id
        load_balancer_backend_address_pool_ids = []
      }
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "example-autoscale" {
  name = "example-autoscale"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  target_resource_id = azurerm_virtual_machine_scale_set.example-vmss.id
  profile {
    name = "example-profile"
    capacity {
      default = var.capacity
      minimum = var.capacity
      maximum = var.capacity
    }
    rule {
      name = var.scale_rule_name
      scale_action {
        direction = var.scale_rule_scale_action_direction
        type = var.scale_rule_scale_action_type
        value = var.scale_rule_scale_action_value
        cooldown = var.scale_rule_scale_action_cooldown
      }
      metric_trigger {
        metric_name = var.scale_rule_metric_name
        namespace = var.scale_rule_metric_namespace
        aggregation = var.scale_rule_metric_aggregation
        operator = var.scale_rule_metric_operator
        threshold = var.scale_rule_metric_threshold
      }
    }
  }
}