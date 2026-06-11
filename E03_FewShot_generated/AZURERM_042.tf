provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "vmss_name" {
  type        = string
  description = "The name of the virtual machine scale set"
}

variable "instance_count" {
  type        = number
  description = "The initial number of instances in the scale set"
}

variable "admin_username" {
  type        = string
  description = "The administrator username for the virtual machines"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "The administrator password for the virtual machines"
}

variable "autoscale_profile_name" {
  type        = string
  description = "The name of the autoscale profile"
}

variable "autoscale_rule_name" {
  type        = string
  description = "The name of the autoscale rule"
}

variable "autoscale_min_instances" {
  type        = number
  description = "The minimum number of instances in the scale set"
}

variable "autoscale_max_instances" {
  type        = number
  description = "The maximum number of instances in the scale set"
}

variable "autoscale_cpu_threshold" {
  type        = number
  description = "The CPU threshold for scaling"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "example-public-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
}

resource "azurerm_lb" "example" {
  name                = "example-lb"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  frontend_ip_configuration {
    name                 = "example-frontend-ip"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "example-backend-address-pool"
}

resource "azurerm_lb_rule" "example" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "example-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.example.id
  frontend_ip_configuration_name = "example-frontend-ip"
}

resource "azurerm_virtual_machine_scale_set" "example" {
  name                = var.vmss_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  upgrade_policy_mode = "Rolling"

  automatic_os_upgrade_policy {
    disable_automatic_rollback = false
    enable_automatic_os_upgrade = true
  }

  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 5
    pause_time_between_batches              = "PT0S"
  }

  sku {
    name     = "Standard_DS2_v2"
    tier     = "Standard"
    capacity = var.instance_count
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    caching              = "ReadWrite"
    create_option        = "FromImage"
    managed_disk_type    = "Standard_LRS"
    os_type              = "Linux"
  }

  os_profile {
    admin_username = var.admin_username
    admin_password = var.admin_password
    computer_name_prefix = "example"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_profile {
    name    = "example-network-profile"
    primary = true

    ip_configuration {
      name                                   = "example-ip-configuration"
      primary                                = true
      subnet_id                              = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.example.id]
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "example" {
  name                = var.autoscale_profile_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  target_resource_id  = azurerm_virtual_machine_scale_set.example.id

  profile {
    name = var.autoscale_profile_name

    capacity {
      default = var.instance_count
      minimum = var.autoscale_min_instances
      maximum = var.autoscale_max_instances
    }

    rule {
      name      = var.autoscale_rule_name
      scale_action {
        cooldown_time = "PT1M"
        direction     = "Increase"
        type          = "ChangeCount"
        value         = "1"
      }

      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualmachinescalesets"
        resource_id        = azurerm_virtual_machine_scale_set.example.id
        threshold_operator = "GreaterThan"
        threshold          = var.autoscale_cpu_threshold
      }
    }

    rule {
      name      = "ScaleDown"
      scale_action {
        cooldown_time = "PT1M"
        direction     = "Decrease"
        type          = "ChangeCount"
        value         = "1"
      }

      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualmachinescalesets"
        resource_id        = azurerm_virtual_machine_scale_set.example.id
        threshold_operator = "LessThan"
        threshold          = var.autoscale_cpu_threshold
      }
    }
  }
}