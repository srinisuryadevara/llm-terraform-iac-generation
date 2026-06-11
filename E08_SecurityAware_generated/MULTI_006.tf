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
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# AWS RDS Instance
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

# AWS Security Group
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

# AWS KMS Key
resource "aws_kms_key" "example" {
  description             = "Example KMS Key"
  deletion_window_in_days = 10
  tags = {
    Environment = var.environment
  }
}

# Azure SQL Database
resource "azurerm_mssql_server" "example" {
  name                = "example-sql-server"
  resource_group_name = var.azure_resource_group_name
  location            = var.azure_location
  version             = "12.0"

  administrator_login          = var.azure_sql_username
  administrator_login_password = var.azure_sql_password

  extended_auditing_policy {
    storage_endpoint                        = var.azure_storage_account_url
    storage_account_access_key              = var.azure_storage_account_key
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 0
  }

  tags = {
    Environment = var.environment
  }
}

# Azure SQL Database Firewall Rule
resource "azurerm_mssql_firewall_rule" "example" {
  name                = "example-firewall-rule"
  resource_group_name = var.azure_resource_group_name
  server_name         = azurerm_mssql_server.example.name
  start_ip_address    = var.azure_allowed_cidr_start
  end_ip_address      = var.azure_allowed_cidr_end
}

# Azure Storage Account
resource "azurerm_storage_account" "example" {
  name                     = "examplestorageaccount"
  resource_group_name      = var.azure_resource_group_name
  location                 = var.azure_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version = "TLS1_2"

  tags = {
    Environment = var.environment
  }
}

# GCP Cloud SQL Instance
resource "google_sql_database_instance" "example" {
  name                = "example-sql-instance"
  region              = var.gcp_region
  database_version   = "POSTGRES_13"
  deletion_protection = false

  settings {
    tier = "db-g1-small"

    ip_configuration {
      ipv4_enabled = true
      require_ssl  = true
      authorized_networks {
        name  = "example-network"
        value = var.gcp_allowed_cidr
      }
    }
  }

  tags = {
    Environment = var.environment
  }
}

# GCP KMS Key
resource "google_kms_key_ring" "example" {
  name     = "example-key-ring"
  location = var.gcp_location
}

resource "google_kms_crypto_key" "example" {
  name     = "example-crypto-key"
  key_ring = google_kms_key_ring.example.id
}

resource "google_sql_database_instance" "example-encrypted" {
  name                = "example-sql-instance-encrypted"
  region              = var.gcp_region
  database_version   = "POSTGRES_13"
  deletion_protection = false

  settings {
    tier = "db-g1-small"

    disk_encryption_configuration {
      kms_key_name = google_kms_crypto_key.example.id
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

  tags = {
    Environment = var.environment
  }
}