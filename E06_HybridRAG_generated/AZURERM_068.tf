# The Azure Active Resource Manager Terraform provider
provider "azurerm" {
  version = "=1.36.1"
}

# Reference to the current subscription.  Used when creating role assignments
data "azurerm_subscription" "current" {}

# The main resource group for this deployment
resource "azurerm_resource_group" "default" {
  name     = "${var.name}-${var.environment}-rg"
  location = "${var.location}"
}

# Azure Event Hub namespace
resource "azurerm_eventhub_namespace" "example" {
  name                = "${var.name}-${var.environment}-eh-namespace"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  sku                 = "Standard"
  capacity            = 1
  kafka_enabled       = false
}

# Azure Event Hub
resource "azurerm_eventhub" "example" {
  name                = "${var.name}-${var.environment}-eh"
  namespace_name      = azurerm_eventhub_namespace.example.name
  resource_group_name = azurerm_resource_group.default.name
  partition_count     = 2
  message_retention   =! 1
}

# Azure Event Hub consumer group
resource "azurerm_eventhub_consumer_group" "example" {
  name                = "${var.name}-${var.environment}-eh-cg"
  namespace_name      = azurerm_eventhub_namespace.example.name
  eventhub_name       = azurerm_eventhub.example.name
  resource_group_name = azurerm_resource_group.default.name
}