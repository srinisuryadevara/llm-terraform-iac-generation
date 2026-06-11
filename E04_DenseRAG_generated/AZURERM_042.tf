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

variable "tags" {
  type = map(string)
}

variable "sku_name" {
  type = string
}

variable "instance_count" {
  type = number
}

variable "upgrade_mode" {
  type = string
}

variable "health_probe_id" {
  type = string
}

variable "autoscale_profile_name" {
  type = string
}

variable "autoscale_rule_name" {
  type = string
}

variable "autoscale_rule_metric_name" {
  type = string
}

variable "autoscale_rule_operator" {
  type = string
}

variable "autoscale_rule_threshold" {
  type = number
}

variable "autoscale_rule_direction" {
  type = string
}

variable "autoscale_rule_type" {
  type = string
}

variable "autoscale_rule_value" {
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

  upgrade_policy_mode = var.upgrade_mode

  sku {
    name     = var.sku_name
    tier     = "Standard"
    capacity = var.instance_count
  }

  os_profile {
    computer_name_prefix = "vmss"
    admin_username       = var.admin_username
    admin_password       = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_profile {
    name    = "network-profile"
    primary = true

    ip_configuration {
      name                                   = "ip-config"
      primary                                = true
      subnet_id                              = var.health_probe_id
      load_balancer_backend_address_pool_ids = []
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = var.autoscale_profile_name
  resource_group_name = var.rg_name
  location            = var.location
  target_resource_id  = azurerm_virtual_machine_scale_set.vmss.id

  profile {
    name = var.autoscale_profile_name

    capacity {
      default = var.instance_count
      minimum = 1
      maximum = 10
    }

    rule {
      name      = var.autoscale_rule_name
      scale_action {
        cooldown  = "300"
        direction = var.autoscale_rule_direction
        type      = var.autoscale_rule_type
        value     = var.autoscale_rule_value
      }

      metric_trigger {
        metric_name         = var.autoscale_rule_metric_name
        namespace           = "microsoft.compute/virtualmachinescalesets"
        operator            = var.autoscale_rule_operator
        statistic           = "Average"
        threshold           = var.autoscale_rule_threshold
        time_aggregation    = "Average"
        time_grain          = "PT1M"
        time_window         = "PT5M"
        metric_resource_id  = azurerm_virtual_machine_scale_set.vmss.id
        divide_per_instance = false
      }
    }
  }
}