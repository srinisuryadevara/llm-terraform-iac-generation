# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
  version         = "3.34.0"
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# AWS RDS
resource "aws_db_instance" "example" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t2.micro"
  name                 = "exampledb"
  username             = var.aws_rds_username
  password             = var.aws_rds_password
  vpc_security_group_ids = [aws_security_group.example.id]
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.example.arn
  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow inbound traffic on port 5432"
  vpc_id      = var.aws_vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.aws_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_kms_key" "example" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  tags = {
    Environment = var.environment
  }
}

# Azure SQL Database
resource "azurerm_resource_group" "example" {
  name     = "example-rg"
  location = var.azure_location
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_sql_server" "example" {
  name                = "example-sql-server"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"

  administrator_login          = var.azure_sql_username
  administrator_login_password = var.azure_sql_password

  extended_auditing_policy {
    storage_endpoint                        = var.azure_storage_account
    storage_account_access_key              = var.azure_storage_access_key
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 0
  }

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_sql_database" "example" {
  name                = "example-sql-database"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_sql_server.example.name
  edition             = "Standard"
  collation           = "SQL_Latin1_General_CP1_CI_AS"
  max_size_bytes      = "1073741824"

  short_term_retention_policy {
    retention_days = 35
  }

  long_term_retention_policy {
    weekly_retention  = "PT0S"
    monthly_retention = "PT0S"
    yearly_retention  = "PT0S"
    week_of_year      = 0
  }

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "examplestorageaccount"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version = "TLS1_2"

  tags = {
    Environment = var.environment
  }
}

# GCP Cloud SQL
resource "google_sql_database_instance" "example" {
  name                = "example-sql-instance"
  region              = var.gcp_region
  database_version   = "POSTGRES_13"
  deletion_protection = false

  settings {
    tier = "db-n1-standard-1"
    disk_size = 20
    disk_type = "PD_SSD"
    availability_type = "REGIONAL"
    database_flags {
      name  = "cloudsql.enable_pgaudit"
      value = "on"
    }
    ip_configuration {
      ipv4_enabled = true
      require_ssl  = true
      authorized_networks {
        name  = "example-network"
        value = var.gcp_allowed_cidr
      }
    }
  }

  depends_on = [google_service_account.example]

  tags = {
    Environment = var.environment
  }
}

resource "google_service_account" "example" {
  account_id = "example-sa"
}

resource "google_kms_key_ring" "example" {
  name     = "example-keyring"
  location = var.gcp_location
}

resource "google_kms_crypto_key" "example" {
  name     = "example-key"
  key_ring = google_kms_key_ring.example.id
}

resource "google_kms_crypto_key_version" "example" {
  crypto_key = google_kms_crypto_key.example.id
}

resource "google_sql_ssl_cert" "example" {
  common_name = "example-cert"
  instance   = google_sql_database_instance.example.name
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_vpc_id" {
  type        = string
  description = "AWS VPC ID"
}

variable "aws_rds_username" {
  type        = string
  description = "AWS RDS username"
}

variable "aws_rds_password" {
  type        = string
  description = "AWS RDS password"
}

variable "aws_allowed_cidr" {
  type        = string
  description = "AWS allowed CIDR"
}

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "azure_client_id" {
  type        = string
  description = "Azure client ID"
}

variable "azure_client_secret" {
  type        = string
  description = "Azure client secret"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure tenant ID"
}

variable "azure_location" {
  type        = string
  description = "Azure location"
}

variable "azure_sql_username" {
  type        = string
  description = "Azure SQL username"
}

variable "azure_sql_password" {
  type        = string
  description = "Azure SQL password"
}

variable "azure_storage_account" {
  type        = string
  description = "Azure storage account"
}

variable "azure_storage_access_key" {
  type        = string
  description = "Azure storage access key"
}

variable "gcp_project" {
  type        = string
  description = "GCP project"
}

variable "gcp_region" {
  type        = string
  description = "GCP region"
}

variable "gcp_location" {
  type        = string
  description = "GCP location"
}

variable "gcp_allowed_cidr" {
  type        = string
  description = "GCP allowed CIDR"
}

variable "environment" {
  type        = string
  description = "Environment"
}