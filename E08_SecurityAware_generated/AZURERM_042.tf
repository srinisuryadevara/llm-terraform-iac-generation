provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "location" {
  type        = string
  description = "The location where the resources will be created"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "vmss_name" {
  type        = string
  description = "The name of the Virtual Machine Scale Set"
}

variable "admin_username" {
  type        = string
  sensitive   = true
  description = "The administrator username for the Virtual Machine Scale Set"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "The administrator password for the Virtual Machine Scale Set"
}

variable "ssh_source_cidr" {
  type        = string
  description = "The source CIDR for SSH access"
}

variable "instance_count" {
  type        = number
  description = "The initial number of instances in the Virtual Machine Scale Set"
}

variable "min_instances" {
  type        = number
  description = "The minimum number of instances in the Virtual Machine Scale Set"
}

variable "max_instances" {
  type        = number
  description = "The maximum number of instances in the Virtual Machine Scale Set"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "example"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "example-virtual-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = "example"
  }
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  tags = {
    environment = "example"
  }
}

resource "azurerm_public_ip" "example" {
  name                = "example-public-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
  tags = {
    environment = "example"
  }
}

resource "azurerm_lb" "example" {
  name                = "example-load-balancer"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "example-frontend-ip"
    public_ip_address_id = azurerm_public_ip.example.id
  }
  tags = {
    environment = "example"
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
  frontend_ip_configuration_name = "example-frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example.id]
}

resource "azurerm_network_security_group" "example" {
  name                = "example-network-security-group"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = "example"
  }
  security_rule {
    name                       = "example-ssh-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_source_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_virtual_machine_scale_set" "example" {
  name                = var.vmss_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  upgrade_policy_mode  = "Rolling"
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
    disk_size_gb         = 30
  }
  os_profile {
    computer_name_prefix = "example"
    admin_username       = var.admin_username
    admin_password       = var.admin_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  network_profile {
    name    = "example-network-profile"
    primary = true
    ip_configuration {
      name                                   = "example-ip-configuration"
      primary                               = true
      subnet_id                             = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.example.id]
    }
  }
  tags = {
    environment = "example"
  }
}

resource "azurerm_monitor_autoscale_setting" "example" {
  name                = "example-autoscale-setting"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  target_resource_id  = azurerm_virtual_machine_scale_set.example.id
  profile {
    name = "example-profile"
    capacity {
      default = var.instance_count
      minimum = var.min_instances
      maximum = var.max_instances
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualmachinescalesets"
        resource_id        = azurerm_virtual_machine_scale_set.example.id
        operator           = "GreaterThan"
        statistic          = "Average"
        threshold          = 75
        time_aggregation   = "Average"
        time_granularity   = "PT1M"
        time_window        = "PT5M"
        metric_resource_id = azurerm_virtual_machine_scale_set.example.id
        divide_per_instance = true
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = 300
      }
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        namespace          = "microsoft.compute/virtualmachinescalesets"
        resource_id        = azurerm_virtual_machine_scale_set.example.id
        operator           = "LessThan"
        statistic          = "Average"
        threshold          = 25
        time_aggregation   = "Average"
        time_granularity   = "PT1M"
        time_window        = "PT5M"
        metric_resource_id = azurerm_virtual_machine_scale_set.example.id
        divide_per_instance = true
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = 300
      }
    }
  }
  tags = {
    environment = "example"
  }
}