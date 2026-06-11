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
    random = {
      source  = "hashicorp/random"
      version = "~>3.4.3"
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

variable "publisher" {
  type = string
}

variable "offer" {
  type = string
}

variable "sku" {
  type = string
}

variable "version" {
  type = string
}

variable "instance_count" {
  type = number
}

variable "min_instances" {
  type = number
}

variable "max_instances" {
  type = number
}

variable "scale_out_cooldown" {
  type = number
}

variable "scale_in_cooldown" {
  type = number
}

variable "scale_out_rule" {
  type = object({
    metric_name         = string
    operator            = string
    threshold           = number
    time_aggregation    = string
    time_grain          = string
    time_window         = string
    metric_resource_id  = string
    direction           = string
    type                = string
    value               = number
    scale_action_amount = number
    scale_action_type   = string
  })
}

variable "scale_in_rule" {
  type = object({
    metric_name         = string
    operator            = string
    threshold           = number
    time_aggregation    = string
    time_grain          = string
    time_window         = string
    metric_resource_id  = string
    direction           = string
    type                = string
    value               = number
    scale_action_amount = number
    scale_action_type   = string
  })
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
    name    = "vmss-network-profile"
    primary = true

    ip_configuration {
      name                                   = "vmss-ip-config"
      primary                                = true
      subnet_id                              = azurerm_subnet.vmss_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.vmss_pool.id]
    }
  }

  storage_profile_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
    version   = var.version
  }

  storage_profile_os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = var.tags
}

resource "azurerm_subnet" "vmss_subnet" {
  name                 = "vmss-subnet"
  resource_group_name = var.rg_name
  virtual_network_name = azurerm_virtual_network.vmss_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_virtual_network" "vmss_vnet" {
  name                = "vmss-vnet"
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_lb" "vmss_lb" {
  name                = "vmss-lb"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "vmss-lb-frontend"
    public_ip_address_id = azurerm_public_ip.vmss_public_ip.id
  }
}

resource "azurerm_public_ip" "vmss_public_ip" {
  name                = "vmss-public-ip"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"
  allocation_method   = "Dynamic"
}

resource "azurerm_lb_backend_address_pool" "vmss_pool" {
  name            = "vmss-pool"
  loadbalancer_id = azurerm_lb.vmss_lb.id
}

resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "vmss-autoscale"
  location            = var.location
  resource_group_name = var.rg_name

  target_resource_id = azurerm_virtual_machine_scale_set.vmss.id

  profile {
    name = "default"

    capacity {
      default = var.instance_count
      minimum = var.min_instances
      maximum = var.max_instances
    }

    rule {
      name      = "scale_out"
      scale_action {
        cooldown  = var.scale_out_cooldown
        direction = var.scale_out_rule.direction
        type      = var.scale_out_rule.type
        value     = var.scale_out_rule.scale_action_amount
      }

      metric_trigger {
        metric_name         = var.scale_out_rule.metric_name
        namespace           = "microsoft.compute/virtualmachinescalesets"
        operator            = var.scale_out_rule.operator
        statistic           = "Average"
        threshold           = var.scale_out_rule.threshold
        time_aggregation    = var.scale_out_rule.time_aggregation
        time_grain          = var.scale_out_rule.time_grain
        time_window         = var.scale_out_rule.time_window
        metric_resource_id  = azurerm_virtual_machine_scale_set.vmss.id
        divide_per_instance = false
      }
    }

    rule {
      name      = "scale_in"
      scale_action {
        cooldown  = var.scale_in_cooldown
        direction = var.scale_in_rule.direction
        type      = var.scale_in_rule.type
        value     = var.scale_in_rule.scale_action_amount
      }

      metric_trigger {
        metric_name         = var.scale_in_rule.metric_name
        namespace           = "microsoft.compute/virtualmachinescalesets"
        operator            = var.scale_in_rule.operator
        statistic           = "Average"
        threshold           = var.scale_in_rule.threshold
        time_aggregation    = var.scale_in_rule.time_aggregation
        time_grain          = var.scale_in_rule.time_grain
        time_window         = var.scale_in_rule.time_window
        metric_resource_id  = azurerm_virtual_machine_scale_set.vmss.id
        divide_per_instance = false
      }
    }
  }
}