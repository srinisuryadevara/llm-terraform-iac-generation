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

variable "scale_out" {
  type = number
}

variable "scale_in" {
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

resource "azurerm_network_interface" "example-nic" {
  name = "example-nic"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location

  ip_configuration {
    name = "example-ip-config"
    subnet_id = azurerm_subnet.example-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "example-vmss" {
  name = var.vmss_name
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  sku = var.sku
  instances = var.instance_count
  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface {
    name = "example-nic"
    network_interface_id = azurerm_network_interface.example-nic.id
  }

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "16.04-LTS"
    version = "latest"
  }
}

resource "azurerm_monitor_autoscale_setting" "example-autoscale" {
  name = "example-autoscale"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  target_resource_id = azurerm_linux_virtual_machine_scale_set.example-vmss.id

  profile {
    name = "example-profile"

    capacity {
      default = var.capacity
      minimum = var.capacity
      maximum = var.capacity
    }

    rule {
      scale_action {
        cooldown = "5"
        direction = "Increase"
        type = "ChangeCount"
        value = var.scale_out
      }

      metric_trigger {
        metric_name = "Percentage CPU"
        namespace = "microsoft.compute/virtualmachinescalesets"
        resource_id = azurerm_linux_virtual_machine_scale_set.example-vmss.id
        operator = "GreaterThan"
        statistic = "Average"
        threshold = 0.5
        time_aggregation = "Average"
        time_grain = "PT1M"
        time_window = "PT5M"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.example-vmss.id
      }
    }

    rule {
      scale_action {
        cooldown = "5"
        direction = "Decrease"
        type = "ChangeCount"
        value = var.scale_in
      }

      metric_trigger {
        metric_name = "Percentage CPU"
        namespace = "microsoft.compute/virtualmachinescalesets"
        resource_id = azurerm_linux_virtual_machine_scale_set.example-vmss.id
        operator = "LessThan"
        statistic = "Average"
        threshold = 0.2
        time_aggregation = "Average"
        time_grain = "PT1M"
        time_window = "PT5M"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.example-vmss.id
      }
    }
  }
}
!