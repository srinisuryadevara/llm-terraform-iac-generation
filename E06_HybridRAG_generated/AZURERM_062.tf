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
# Variables
# ------------------------------------------------------------------------------------------------------
variable "resource_token" {
  type        = string
  description = "Resource token"
}

variable "location" {
  type        = string
  description = "Location"
}

variable "rg_name" {
  type        = string
  description = "Resource group name"
}

variable "os_type" {
  type        = string
  description = "OS type"
}

variable "sku_name" {
  type        = string
  description = "SKU name"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
}

variable "vm_size" {
  type        = string
  description = "VM size"
}

variable "admin_username" {
  type        = string
  description = "Admin username"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Admin password"
}

variable "publisher" {
  type        = string
  description = "Publisher"
}

variable "offer" {
  type        = string
  description = "Offer"
}

variable "sku" {
  type        = string
  description = "SKU"
}

variable "version" {
  type        = string
  description = "Version"
}

variable "min_instances" {
  type        = number
  description = "Minimum instances"
}

variable "max_instances" {
  type        = number
  description = "Maximum instances"
}

variable "scale_out_threshold" {
  type        = number
  description = "Scale out threshold"
}

variable "scale_in_threshold" {
  type        = number
  description = "Scale in threshold"
}

# ------------------------------------------------------------------------------------------------------
# Deploy app service plan
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "plan_name" {
  name          = var.resource_token
  resource_type = "azurerm_app_service_plan"
  random_length = 0
  clean_input   = true
}

resource "azurerm_service_plan" "plan" {
  name                = azurecaf_name.plan_name.result
  location            = var.location
  resource_group_name = var.rg_name
  os_type             = var.os_type
  sku_name            = var.sku_name

  tags = var.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy virtual network
# ------------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.resource_token}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.rg_name

  tags = var.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy subnet
# ------------------------------------------------------------------------------------------------------
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-${var.resource_token}"
  resource_group_name = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ------------------------------------------------------------------------------------------------------
# Deploy public IP
# ------------------------------------------------------------------------------------------------------
resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.resource_token}"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Dynamic"

  tags = var.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy load balancer
# ------------------------------------------------------------------------------------------------------
resource "azurerm_lb" "lb" {
  name                = "lb-${var.resource_token}"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  tags = var.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy load balancer backend pool
# ------------------------------------------------------------------------------------------------------
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = "backend-pool"
  loadbalancer_id = azurerm_lb.lb.id
}

# ------------------------------------------------------------------------------------------------------
# Deploy load balancer rule
# ------------------------------------------------------------------------------------------------------
resource "azurerm_lb_rule" "rule" {
  name                           = "rule"
  loadbalancer_id                = azurerm_lb.lb.id
  frontend_ip_configuration_name = "frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
}

# ------------------------------------------------------------------------------------------------------
# Deploy virtual machine scale set
# ------------------------------------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "vmss-${var.resource_token}"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = var.sku
  instances           = var.min_instances
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  source_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
    version   = var.version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name                                   = "ipconfig"
      primary                               = true
      subnet_id                             = azurerm_subnet.subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
    }
  }

  tags = var.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy autoscale setting
# ------------------------------------------------------------------------------------------------------
resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "autoscale-${var.resource_token}"
  location            = var.location
  resource_group_name = var.rg_name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id

  profile {
    name = "default"

    capacity {
      default = var.min_instances
      minimum = var.min_instances
      maximum = var.max_instances
    }

    rule {
      name      = "scale_out"
      scale_action {
        cooldown  = "5"
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
      }

      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualmachinescalesets"
        resource_id        = azurerm_linux_virtual_machine_scale_set.vmss.id
        operator           = "GreaterThan"
        statistic          = "Average"
        threshold          = var.scale_out_threshold
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT5M"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
      }
    }

    rule {
      name      = "scale_in"
      scale_action {
        cooldown  = "5"
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
      }

      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualmachinescalesets"
        resource_id        = azurerm_linux_virtual_machine_scale_set.vmss.id
        operator           = "LessThan"
        statistic          = "Average"
        threshold          = var.scale_in_threshold
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT5M"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
      }
    }
  }
}