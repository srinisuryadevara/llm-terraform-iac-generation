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
  }

  network_profile {
    name    = var.network_profile_name
    primary = true

    ip_configuration {
      name                                   = var.ip_configuration_name
      primary                                = true
      subnet_id                              = var.subnet_id
      load_balancer_backend_address_pool_ids = var.load_balancer_backend_address_pool_ids
    }
  }

  tags = var.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy autoscale setting
# ------------------------------------------------------------------------------------------------------
resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = var.autoscale_name
  resource_group_name = var.rg_name
  location            = var.location
  target_resource_id  = azurerm_virtual_machine_scale_set.vmss.id

  profile {
    name = var.profile_name

    capacity {
      default = var.initial_instance_count
      minimum = var.minimum_instance_count
      maximum = var.maximum_instance_count
    }

    rule {
      metric_trigger {
        metric_name        = var.metric_name
        namespace          = var.metric_namespace
        resource_id        = azurerm_virtual_machine_scale_set.vmss.id
        resource_type      = "Microsoft.Compute/virtualMachineScaleSets"
        time_grain         = var.time_grain
        statistic          = var.statistic
        time_window        = var.time_window
        time_aggregation   = var.time_aggregation
        operator           = var.operator
        threshold          = var.threshold
      }

      scale_action {
        direction = var.direction
        type      = var.scale_action_type
        value     = var.scale_action_value
        cooldown  = var.cooldown
      }
    }
  }
}