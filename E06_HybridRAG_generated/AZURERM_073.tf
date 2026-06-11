terraform {
  required_providers {
    azurerm = {
      version = "~>3.47.0"
      source  = "hashicorp/azurerm"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~>1.2.24"
    }
  }
}

variable "resource_token" {
  type = string
}

variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "os_type" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "vm_size" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "ssh_key_path" {
  type = string
}

variable "image_publisher" {
  type = string
}

variable "image_offer" {
  type = string
}

variable "image_sku" {
  type = string
}

variable "image_version" {
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

variable "autoscale_scale_out_threshold" {
  type = number
}

variable "autoscale_scale_in_threshold" {
  type = number
}

resource "azurecaf_name" "vmss_name" {
  name          = var.resource_token
  resource_type = "azurerm_virtual_machine_scale_set"
  random_length = 0
  clean_input   = true
}

resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = azurecaf_name.vmss_name.result
  location            = var.location
  resource_group_name = var.rg_name
  upgrade_policy_mode = "Rolling"

  sku {
    name     = var.sku_name
    tier     = "Standard"
    capacity = var.autoscale_default_instances
  }

  os_profile {
    computer_name_prefix = "vmss"
    admin_username       = var.admin_username
    admin_password       = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = file(var.ssh_key_path)
    }
  }

  storage_profile_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  storage_profile_os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_profile {
    name    = "vmss-network-profile"
    primary = true

    ip_configuration {
      name      = "vmss-ip-config"
      primary   = true
      subnet_id = azurerm_subnet.vmss_subnet.id
    }
  }

  tags = var.tags
}

resource "azurerm_virtual_network" "vmss_vnet" {
  name                = "vmss-vnet"
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "vmss_subnet" {
  name                 = "vmss-subnet"
  resource_group_name = var.rg_name
  virtual_network_name = azurerm_virtual_network.vmss_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "vmss-autoscale"
  resource_group_name = var.rg_name
  location            = var.location
  target_resource_id  = azurerm_virtual_machine_scale_set.vmss.id

  profile {
    name = "default"

    capacity {
      default = var.autoscale_default_instances
      minimum = var.autoscale_min_instances
      maximum = var.autoscale_max_instances
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualmachinescalesets"
        resource_id        = azurerm_virtual_machine_scale_set.vmss.id
        operator           = "GreaterThan"
        statistic          = "Average"
        threshold          = var.autoscale_scale_out_threshold
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT5M"
        metric_resource_id = azurerm_virtual_machine_scale_set.vmss.id
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualmachinescalesets"
        resource_id        = azurerm_virtual_machine_scale_set.vmss.id
        operator           = "LessThan"
        statistic          = "Average"
        threshold          = var.autoscale_scale_in_threshold
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT5M"
        metric_resource_id = azurerm_virtual_machine_scale_set.vmss.id
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}