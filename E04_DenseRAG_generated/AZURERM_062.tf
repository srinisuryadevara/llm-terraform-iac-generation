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

# ------------------------------------------------------------------------------------------------------
# Deploy virtual machine scale set
# ------------------------------------------------------------------------------------------------------
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
    tier     = var.sku_tier
    capacity = var.initial_instance_count
  }

  storage_profile_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  storage_profile_os_disk {
    caching              = var.os_disk_caching
    create_option        = var.os_disk_create_option
    managed_disk_type    = var.os_disk_managed_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  os_profile {
    computer_name_prefix = var.computer_name_prefix
    admin_username       = var.admin_username
    admin_password       = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = var.disable_password_authentication

    ssh_key {
      path     = var.ssh_key_path
      key_data = var.ssh_key_data
    }
  }

  tags = var.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy autoscale setting
# ------------------------------------------------------------------------------------------------------
resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = azurecaf_name.vmss_name.result
  resource_group_name = var.rg_name
  location            = var.location
  target_resource_id  = azurerm_virtual_machine_scale_set.vmss.id

  profile {
    name = "default"

    capacity {
      default = var.initial_instance_count
      minimum = var.min_instance_count
      maximum = var.max_instance_count
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualmachinescalesets"
        resource_id        = azurerm_virtual_machine_scale_set.vmss.id
        operator           = "GreaterThan"
        statistic          = "Average"
        threshold          = var.cpu_threshold
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
        threshold          = var.cpu_threshold
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