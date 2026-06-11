# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

# Create a virtual network
resource "azurerm_virtual_network" "example" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Create a subnet
resource "azurerm_subnet" "example" {
  name                 = var.subnet_name
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a public IP address
resource "azurerm_public_ip" "example" {
  name                = var.public_ip_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
}

# Create a load balancer
resource "azurerm_load_balancer" "example" {
  name                = var.load_balancer_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  frontend_ip_configuration {
    name                 = var.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

# Create a backend address pool
resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_load_balancer.example.id
  name            = var.backend_address_pool_name
}

# Create a health probe
resource "azurerm_lb_probe" "example" {
  loadbalancer_id = azurerm_load_balancer.example.id
  name            = var.health_probe_name
  port            = 80
}

# Create a load balancer rule
resource "azurerm_lb_rule" "example" {
  loadbalancer_id                = azurerm_load_balancer.example.id
  name                           = var.load_balancer_rule_name
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = var.frontend_ip_configuration_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example.id]
  probe_id                       = azurerm_lb_probe.example.id
}

# Create a virtual machine scale set
resource "azurerm_linux_virtual_machine_scale_set" "example" {
  name                = var.virtual_machine_scale_set_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  sku {
    name     = var.virtual_machine_size
    tier     = "Standard"
    capacity = var.initial_instance_count
  }

  admin_username = var.admin_username
  admin_ssh_key {
    username   = var.admin_username
    public_key = file("${path.module}/ssh-keys/terraform-azure.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "83-gen2"
    version   = "latest"
  }

  custom_data = filebase64("${path.module}/app-scripts/app1-cloud-init.txt")

  network_interface {
    name    = var.network_interface_name
    primary = true

    ip_configuration {
      name                                   = var.ip_configuration_name
      primary                                 = true
      subnet_id                               = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.example.id]
    }
  }

  tags = var.common_tags
}

# Create an autoscale setting
resource "azurerm_monitor_autoscale_setting" "example" {
  name                = var.autoscale_setting_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  target_resource_id = azurerm_linux_virtual_machine_scale_set.example.id

  autoscale_profile {
    name = var.autoscale_profile_name

    capacity {
      default = var.initial_instance_count
      minimum = var.minimum_instance_count
      maximum = var.maximum_instance_count
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualMachinesScaleSets"
        resource_id        = azurerm_linux_virtual_machine_scale_set.example.id
        operator           = "GreaterThan"
        statistic          = "Average"
        threshold          = 75
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT5M"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.example.id
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualMachinesScaleSets"
        resource_id        = azurerm_linux_virtual_machine_scale_set.example.id
        operator           = "LessThan"
        statistic          = "Average"
        threshold          = 25
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT5M"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.example.id
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The location of the resource group"
}

variable "virtual_network_name" {
  type        = string
  description = "The name of the virtual network"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet"
}

variable "public_ip_name" {
  type        = string
  description = "The name of the public IP address"
}

variable "load_balancer_name" {
  type        = string
  description = "The name of the load balancer"
}

variable "frontend_ip_configuration_name" {
  type        = string
  description = "The name of the frontend IP configuration"
}

variable "backend_address_pool_name" {
  type        = string
  description = "The name of the backend address pool"
}

variable "health_probe_name" {
  type        = string
  description = "The name of the health probe"
}

variable "load_balancer_rule_name" {
  type        = string
  description = "The name of the load balancer rule"
}

variable "virtual_machine_scale_set_name" {
  type        = string
  description = "The name of the virtual machine scale set"
}

variable "virtual_machine_size" {
  type        = string
  description = "The size of the virtual machine"
}

variable "initial_instance_count" {
  type        = number
  description = "The initial number of instances"
}

variable "admin_username" {
  type        = string
  description = "The admin username"
}

variable "network_interface_name" {
  type        = string
  description = "The name of the network interface"
}

variable "ip_configuration_name" {
  type        = string
  description = "The name of the IP configuration"
}

variable "autoscale_setting_name" {
  type        = string
  description = "The name of the autoscale setting"
}

variable "autoscale_profile_name" {
  type        = string
  description = "The name of the autoscale profile"
}

variable "minimum_instance_count" {
  type        = number
  description = "The minimum number of instances"
}

variable "maximum_instance_count" {
  type        = number
  description = "The maximum number of instances"
}

variable "common_tags" {
  type        = map(string)
  description = "A map of common tags"
}