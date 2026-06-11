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
  description = "The name of the virtual machine scale set"
}

variable "admin_username" {
  type        = string
  sensitive   = true
  description = "The administrator username for the virtual machines"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "The administrator password for the virtual machines"
}

variable "ssh_source_cidr" {
  type        = string
  description = "The source CIDR for SSH access"
}

variable "instance_count" {
  type        = number
  description = "The initial number of instances in the scale set"
}

variable "min_instances" {
  type        = number
  description = "The minimum number of instances in the scale set"
}

variable "max_instances" {
  type        = number
  description = "The maximum number of instances in the scale set"
}

variable "sku" {
  type        = string
  description = "The SKU of the virtual machines"
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the resources"
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags                = var.tags
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "example" {
  name                        = "example-nsg-rule"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_address_prefix       = var.ssh_source_cidr
  source_port_range          = "*"
  destination_address_prefix  = "*"
  destination_port_range     = "22"
}

resource "azurerm_public_ip" "example" {
  name                = "example-pip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  tags                = var.tags
}

resource "azurerm_lb" "example" {
  name                = "example-lb"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Basic"
  tags                = var.tags
}

resource "azurerm_lb_backend_address_pool" "example" {
  name            = "example-lb-backend-pool"
  loadbalancer_id = azurerm_lb.example.id
}

resource "azurerm_lb_rule" "example" {
  name                           = "example-lb-rule"
  loadbalancer_id                = azurerm_lb.example.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "example-lb-frontend-ip-config"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example.id]
}

resource "azurerm_lb_probe" "example" {
  name            = "example-lb-probe"
  loadbalancer_id = azurerm_lb.example.id
  protocol        = "Tcp"
  port            = 80
}

resource "azurerm_virtual_machine_scale_set" "example" {
  name                = var.vmss_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  upgrade_policy_mode = "Rolling"
  sku {
    name     = var.sku
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
    disk_size_gb         = 30
    disk_encryption_set_id = azurerm_disk_encryption_set.example.id
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
    name    = "example-np"
    primary = true
    ip_configuration {
      name                                   = "example-ip-config"
      primary                               = true
      subnet_id                             = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.example.id]
      load_balancer_inbound_nat_rules_ids    = []
    }
  }
  tags = var.tags
}

resource "azurerm_disk_encryption_set" "example" {
  name                = "example-des"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  key_vault_key_id    = azurerm_key_vault_key.example.id
  tags                = var.tags
}

resource "azurerm_key_vault" "example" {
  name                = "example-kv"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = "standard"
  tenant_id           = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  tags                = var.tags
}

resource "azurerm_key_vault_key" "example" {
  name         = "example-kv-key"
  key_vault_id = azurerm_key_vault.example.id
  key_type     = "RSA"
  key_size     = 2048
  tags         = var.tags
}

resource "azurerm_monitor_autoscale_setting" "example" {
  name                = "example-asc"
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
        time_grain         = "PT1M"
        time_window        = "PT5M"
        metric_resource_id = azurerm_virtual_machine_scale_set.example.id
        divide_per_instance = false
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
        resource_id        = azurerm_virtual_machine_scale_set.example.id
        operator           = "LessThan"
        statistic          = "Average"
        threshold          = 25
        time_aggregation   = "Average"
        time_grain         = "PT1M"
        time_window        = "PT5M"
        metric_resource_id = azurerm_virtual_machine_scale_set.example.id
        divide_per_instance = false
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