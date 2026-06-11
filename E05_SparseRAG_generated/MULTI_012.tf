# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a Secrets Manager secret on AWS
resource "aws_secretsmanager_secret" "example" {
  name = var.aws_secret_name
}

# Create a Key Vault secret on Azure
resource "azurerm_key_vault_secret" "example" {
  name         = var.azure_secret_name
  value        = var.azure_secret_value
  key_vault_id = azurerm_key_vault.example.id
}

# Create a Key Vault on Azure
resource "azurerm_key_vault" "example" {
  name                        = var.azure_key_vault_name
  location                    = var.azure_location
  resource_group_name         = var.azure_resource_group_name
  tenant_id                   = var.azure_tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
}

# Create a Secret Manager secret on GCP
resource "google_secretmanager_secret" "example" {
  secret_id = var.gcp_secret_name
}

# Create a Secret Manager secret version on GCP
resource "google_secretmanager_secret_version" "example" {
  secret      = google_secretmanager_secret.example.id
  secret_data = var.gcp_secret_value
}

# Create an IAM policy for the Secrets Manager secret on AWS
resource "aws_iam_policy" "example" {
  name        = var.aws_iam_policy_name
  description = "Policy for Secrets Manager secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAccessToSecret"
        Effect    = "Allow"
        Action    = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.example.arn
      },
    ]
  })
}

# Create a role for the Key Vault secret on Azure
resource "azurerm_role_definition" "example" {
  name        = var.azure_role_definition_name
  scope       = azurerm_subscription.example.id
  description = "Role definition for Key Vault secret"

  permissions {
    actions = [
      "Microsoft.KeyVault/vaults/secrets/read",
    ]
    not_actions = []
  }

  assignable_scopes = [
    azurerm_subscription.example.id,
  ]
}

# Create a subscription on Azure
resource "azurerm_subscription" "example" {
  subscription_name = var.azure_subscription_name
  subscription_id   = var.azure_subscription_id
}

# Create a service account for the Secret Manager secret on GCP
resource "google_service_account" "example" {
  account_id = var.gcp_service_account_name
}

# Create a key for the service account on GCP
resource "google_service_account_key" "example" {
  service_account_id = google_service_account.example.id
}

# Create an IAM policy for the Secret Manager secret on GCP
resource "google_iam_policy" "example" {
  name        = var.gcp_iam_policy_name
  description = "Policy for Secret Manager secret"

  policy_data = jsonencode({
    bindings = [
      {
        role = "roles/secretmanager.secretAccessor"
        members = [
          "serviceAccount:${google_service_account.example.email}",
        ]
      },
    ]
  })
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_secret_name" {
  type        = string
  description = "AWS Secrets Manager secret name"
}

variable "azure_secret_name" {
  type        = string
  description = "Azure Key Vault secret name"
}

variable "azure_secret_value" {
  type        = string
  description = "Azure Key Vault secret value"
  sensitive   = true
}

variable "azure_key_vault_name" {
  type        = string
  description = "Azure Key Vault name"
}

variable "azure_location" {
  type        = string
  description = "Azure location"
}

variable "azure_resource_group_name" {
  type        = string
  description = "Azure resource group name"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure tenant ID"
}

variable "azure_subscription_name" {
  type        = string
  description = "Azure subscription name"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "azure_role_definition_name" {
  type        = string
  description = "Azure role definition name"
}

variable "gcp_project" {
  type        = string
  description = "GCP project"
}

variable "gcp_region" {
  type        = string
  description = "GCP region"
}

variable "gcp_secret_name" {
  type        = string
  description = "GCP Secret Manager secret name"
}

variable "gcp_secret_value" {
  type        = string
  description = "GCP Secret Manager secret value"
  sensitive   = true
}

variable "gcp_service_account_name" {
  type        = string
  description = "GCP service account name"
}

variable "gcp_iam_policy_name" {
  type        = string
  description = "GCP IAM policy name"
}

variable "aws_iam_policy_name" {
  type        = string
  description = "AWS IAM policy name"
}