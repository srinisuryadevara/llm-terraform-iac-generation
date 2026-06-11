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

variable "vm_size" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type = string
  sensitive = true
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
  resource_group_name = azurerm_resource_group.example.name
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
  name = "example-vmss"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  single_placement_group = true
  upgrade_policy_mode = "Rolling"

  sku {
    name = var.vm_size
    tier = "Standard"
    capacity = 2
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

    ip_configuration {
      name = "example-ip"
      primary = true
      subnet_id = azurerm_subnet.example-subnet.id
      load_balancer_backend_address_pool_ids = []
      load_balancer_inbound_nat_rules_ids = []
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "example-vmss-as" {
  name = "example-vmss-as"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  target_resource_id = azurerm_virtual_machine_scale_set.example-vmss.id

  profile {
    name = "example-profile"

    capacity {
      default = 2
      minimum = 2
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name = "Percentage CPU"
        namespace = "microsoft.compute/virtualmachinescalesets"
        resource_id = azurerm_virtual_machine_scale_set.example-vmss.id
        operator = "GreaterThan"
        threshold = 75
      }

      scale_action {
        direction = "Increase"
        type = "ChangeCount"
        value = "1"
        cooldown = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name = "Percentage CPU"
        namespace = "microsoft.compute/virtualmachinescalesets"
        resource_id = azurerm_virtual_machine_scale_set.example-vmss.id
        operator = "LessThan"
        threshold = 25
      }

      scale_action {
        direction = "Decrease"
        type = "ChangeCount"
        value = "1"
        cooldown = "PT5M"
      }
    }
  }
}