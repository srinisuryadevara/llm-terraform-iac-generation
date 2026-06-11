provider "azurerm" {
  version = "3.34.0"
  features {}
}

variable "region" {
  type        = string
  description = "Azure region"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "ssh_source_cidr" {
  type        = string
  description = "SSH source CIDR"
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

variable "instance_count" {
  type        = number
  description = "Initial instance count"
}

variable "min_instances" {
  type        = number
  description = "Minimum instances"
}

variable "max_instances" {
  type        = number
  description = "Maximum instances"
}

resource "azurerm_resource_group" "example" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.region
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${var.project}-${var.environment}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_subnet" "example" {
  name                 = "${var.project}-${var.environment}-subnet"
  resource_group_name = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "${var.project}-${var.environment}-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = var.ssh_source_cidr
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_network_security_rule" "http" {
  name                        = "HTTP"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_virtual_machine_scale_set" "example" {
  name                = "${var.project}-${var.environment}-vmss"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  upgrade_policy_mode = "Rolling"

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
    name    = "example"
    primary = true

    ip_configuration {
      name                                   = "example"
      primary                                = true
      subnet_id                              = azurerm_subnet.example.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.example.id]
    }
  }

  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_disk_encryption_set" "example" {
  name                = "${var.project}-${var.environment}-des"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  key_vault_key_id    = azurerm_key_vault_key.example.id

  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_key_vault" "example" {
  name                = "${var.project}-${var.environment}-kv"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = "your_tenant_id"
  sku_name            = "standard"

  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_key_vault_key" "example" {
  name         = "${var.project}-${var.environment}-key"
  key_vault_id = azurerm_key_vault.example.id
  key_type     = "RSA"
  key_size     = 2048

  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_monitor_autoscale_setting" "example" {
  name                = "${var.project}-${var.environment}-as"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  target_resource_id = azurerm_virtual_machine_scale_set.example.id

  profile {
    name = "example"

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
        cooldown  = "PT5M"
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
        cooldown  = "PT5M"
      }
    }
  }

  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_lb" "example" {
  name                = "${var.project}-${var.environment}-lb"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"

  tags = {
    environment = var.environment
    project     = var.project
  }
}

resource "azurerm_lb_backend_address_pool" "example" {
  name            = "example"
  loadbalancer_id = azurerm_lb.example.id
}

resource "azurerm_lb_rule" "example" {
  name                           = "example"
  loadbalancer_id                = azurerm_lb.example.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "example"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example.id]
  probe_id                       = azurerm_lb_probe.example.id
}

resource "azurerm_lb_probe" "example" {
  name                = "example"