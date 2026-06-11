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

variable "subnet_id" {
  type = string
}

variable "image_reference_publisher" {
  type = string
}

variable "image_reference_offer" {
  type = string
}

variable "image_reference_sku" {
  type = string
}

variable "image_reference_version" {
  type = string
}

variable "autoscale_min_instances" {
  type = number
}

variable "autoscale_max_instances" {
  type = number
}

variable "autoscale_default_instances" {
  type = number
}

variable "autoscale_scale_up_rule_metric_name" {
  type = string
}

variable "autoscale_scale_up_rule_operator" {
  type = string
}

variable "autoscale_scale_up_rule_threshold" {
  type = number
}

variable "autoscale_scale_down_rule_metric_name" {
  type = string
}

variable "autoscale_scale_down_rule_operator" {
  type = string
}

variable "autoscale_scale_down_rule_threshold" {
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
  name = "example-vmss"
  resource_group_name = azurerm_resource_group.example.name
  location = azurerm_resource_group.example.location
  sku = "Standard_DS2_v2"
  instances = 2
  admin_username = var.admin_username
  admin_password = var.admin_password

  source_image_reference {
    publisher = var.image_reference_publisher
    offer = var.image_reference_offer
    sku = var.image_reference_sku
    version = var.image_reference_version
  }

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name = "example-nic-config"
    primary = true

    ip_configuration {
      name = "example-ip-config"
      primary = true
      subnet_id = azurerm_subnet.example-subnet.id
    }
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
      default = var.autoscale_default_instances
      minimum = var.autoscale_min_instances
      maximum = var.autoscale_max_instances
    }

    rule {
      name = "example-scale-up-rule"
      scale_action {
        cooldown = "300"
        direction = "Increase"
        type = "ChangeCount"
        value = "1"
      }

      metric_trigger {
        metric_name = var.autoscale_scale_up_rule_metric_name
        namespace = "microsoft.compute/virtualmachinescalesets"
        resource_id = azurerm_linux_virtual_machine_scale_set.example-vmss.id
        operator = var.autoscale_scale_up_rule_operator
        statistic = "Average"
        threshold = var.autoscale_scale_up_rule_threshold
        time_aggregation = "Average"
        time_grain = "PT1M"
        time_window = "PT5M"
      }
    }

    rule {
      name = "example-scale-down-rule"
      scale_action {
        cooldown = "300"
        direction = "Decrease"
        type = "ChangeCount"
        value = "1"
      }

      metric_trigger {
        metric_name = var.autoscale_scale_down_rule_metric_name
        namespace = "microsoft.compute/virtualmachinescalesets"
        resource_id = azurerm_linux_virtual_machine_scale_set.example-vmss.id
        operator = var.autoscale_scale_down_rule_operator
        statistic = "Average"
        threshold = var.autoscale_scale_down_rule_threshold
        time_aggregation = "Average"
        time_grain = "PT1M"
        time_window = "PT5M"
      }
    }
  }
}