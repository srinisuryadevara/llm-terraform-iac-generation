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

  single_placement_group = var.single_placement_group

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

    ssh_keys {
      path     = var.ssh_key_path
      key_data = var.ssh_key_data
    }
  }

  network_profile {
    name    = var.network_profile_name
    primary = var.network_profile_primary

    ip_configuration {
      name      = var.ip_configuration_name
      primary   = var.ip_configuration_primary
      subnet_id = var.subnet_id
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
      default = var.default_capacity
      minimum = var.minimum_capacity
      maximum = var.maximum_capacity
    }

    rule {
      metric_trigger {
        metric_name        = var.metric_name
        namespace          = var.metric_namespace
        resource_id        = azurerm_virtual_machine_scale_set.vmss.id
        operator           = var.metric_operator
        threshold          = var.metric_threshold
        time_aggregation   = var.metric_time_aggregation
        time_grain         = var.metric_time_grain
        time_window        = var.metric_time_window
        metric_resource_id = azurerm_virtual_machine_scale_set.vmss.id
        divide_per_instance = var.metric_divide_per_instance
      }

      scale_action {
        direction = var.scale_direction
        type      = var.scale_type
        value     = var.scale_value
        cooldown  = var.scale_cooldown
      }
    }
  }
}