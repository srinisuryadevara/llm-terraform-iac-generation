# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Configure the Google Cloud Provider
provider "google" {
  project = "your-project-id"
  region  = "us-central1"
}

# AWS Secrets Manager
resource "aws_secretsmanager_secret" "example" {
  name = "example-secret"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({"username" = "exampleuser", "password" = "examplepassword"})
}

# Azure Key Vault
resource "azurerm_resource_group" "example" {
  name     = "example-resource-group"
  location = "West US"
}

resource "azurerm_key_vault" "example" {
  name                        = "example-key-vault"
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  tenant_id                   = "your-tenant-id"
  sku_name                    = "standard"
  purge_protection_enabled    = false
}

resource "azurerm_key_vault_access_policy" "example" {
  key_vault_id = azurerm_key_vault.example.id
  tenant_id    = azurerm_key_vault.example.tenant_id
  object_id    = "your-object-id"

  secret_permissions = [
    "Get",
    "Set",
    "List",
    "Delete",
  ]
}

resource "azurerm_key_vault_secret" "example" {
  name         = "example-secret"
  value        = "example-value"
  key_vault_id = azurerm_key_vault.example.id
}

# GCP Secret Manager
resource "google_secret_manager_secret" "example" {
  secret_id = "example-secret"
}

resource "google_secret_manager_secret_version" "example" {
  secret      = google_secret_manager_secret.example.id
  secret_data = "example-data"
}

# Output the secret values
output "aws_secret_value" {
  value       = aws_secretsmanager_secret_version.example.secret_string
  sensitive   = true
}

output "azure_secret_value" {
  value       = azurerm_key_vault_secret.example.value
  sensitive   = true
}

output "gcp_secret_value" {
  value       = google_secret_manager_secret_version.example.secret_data
  sensitive   = true
}