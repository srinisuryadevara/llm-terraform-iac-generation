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
# Deploy resource group
# ------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
  tags     = var.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy virtual network
# ------------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.resource_token}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy subnet
# ------------------------------------------------------------------------------------------------------
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-${var.resource_token}"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ------------------------------------------------------------------------------------------------------
# Deploy network security group
# ------------------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.resource_token}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy network security rule
# ------------------------------------------------------------------------------------------------------
resource "azurerm_network_security_rule" "nsg_rule" {
  name                        = "nsg-rule-${var.resource_token}"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# ------------------------------------------------------------------------------------------------------
# Deploy public ip
# ------------------------------------------------------------------------------------------------------
resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.resource_token}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  tags                = var.tags
}

# ------------------------------------------------------------------------------------------------------
# Deploy load balancer
# ------------------------------------------------------------------------------------------------------
resource "azurerm_lb" "lb" {
  name                = "lb-${var.resource_token}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "lb-frontend-ip"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}

# ------------------------------------------------------------------------------------------------------
# Deploy load balancer backend address pool
# ------------------------------------------------------------------------------------------------------
resource "azurerm_lb_backend_address_pool" "lb_backend_pool" {
  name            = "lb-backend-pool-${var.resource_token}"
  loadbalancer_id = azurerm_lb.lb.id
}

# ------------------------------------------------------------------------------------------------------
# Deploy load balancer probe
# ------------------------------------------------------------------------------------------------------
resource "azurerm_lb_probe" "lb_probe" {
  name            = "lb-probe-${var.resource_token}"
  loadbalancer_id = azurerm_lb.lb.id
  protocol        = "Tcp"
  port            = 22
  interval_in_seconds = 5
  number_of_probes  = 2
}

# ------------------------------------------------------------------------------------------------------
# Deploy load balancer rule
# ------------------------------------------------------------------------------------------------------
resource "azurerm_lb_rule" "lb_rule" {
  name                           = "lb-rule-${var.resource_token}"
  loadbalancer_id                 = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "lb-frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
  probe_id                       = azurerm_lb_probe.lb_probe.id
}

# ------------------------------------------------------------------------------------------------------
# Deploy virtual machine scale set
# ------------------------------------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "vmss-${var.resource_token}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  sku {
    name     = var.sku_name
    tier     = "Standard"
    capacity = var.min_instances
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

  os_profile {
    computer_name_prefix = "vm-${var.resource_token}"
    admin_username       = var.admin_username
    admin_password       = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_profile {
    name    = "network-profile-${var.resource_token}"
    primary = true

    ip_configuration {
      name      = "ip-config-${var.resource_token}"
      primary   = true
      subnet_id = azurerm_subnet.subnet.id
    }
  }
}

# ------------------------------------------------------------------------------------------------------
# Deploy autoscale setting
# ------------------------------------------------------------------------------------------------------
resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "autoscale-${var.resource_token}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  target_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id

  profile {
    name = "default"

    capacity {
      default = var.min_instances
      minimum = var.min_instances
      maximum = var.max_instances
    }

    rule {
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
        resource_id        = azurerm_linux_virtual_machine_scale_set.vmss.id
        operator           = "LessThan"
        statistic          = "Average"
        threshold          = var.scale_in_threshold
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT5M"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
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