# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id      = var.azure_client_id
  client_secret = var.azure_client_secret
  tenant_id      = var.azure_tenant_id
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a random password for the database
resource "random_password" "db_password" {
  length = 16
  special = true
}

# AWS RDS
resource "aws_db_instance" "example" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t2.micro"
  name                 = "exampledb"
  username             = var.db_username
  password             = random_password.db_password.result
  vpc_security_group_ids = [aws_security_group.example.id]
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.example.arn
  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow inbound traffic on port 5432 from specific CIDR"
  vpc_id      = var.aws_vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
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

resource "azurerm_storage_account" "example" {
  name                     = "examplestorage"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_mssql_server" "example" {
  name                = "example-sql-server"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"
  administrator_login          = var.db_username
  administrator_login_password = random_password.db_password.result
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_mssql_database" "example" {
  name        = "exampledb"
  server_id = azurerm_mssql_server.example.id
  sku_name   = "S0"
  max_size_gb = 10
  zone_redundant = true
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_storage_container" "example" {
  name                  = "example-container"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
  tags = {
    Environment = var.environment
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "allow-postgres"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = var.allowed_cidr
    destination_address_prefix = azurerm_mssql_server.example.public_endpoint
  }

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
  tags = {
    Environment = var.environment
  }
}

resource "google_sql_database" "example" {
  name     = "exampledb"
  instance = google_sql_database_instance.example.name
}

resource "google_service_account" "example" {
  account_id = "example-sa"
}

resource "google_project_iam_member" "example" {
  project = var.gcp_project
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.example.email}"
}

resource "google_compute_network" "example" {
  name                    = "example-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "example" {
  name          = "example-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.example.id
}

resource "google_compute_firewall" "example" {
  name    = "example-firewall"
  network = google_compute_network.example.name

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = [var.allowed_cidr]
  target_tags   = ["example-tag"]
}

resource "google_kms_key_ring" "example" {
  name     = "example-keyring"
  location = var.gcp_location
}

resource "google_kms_crypto_key" "example" {
  name     = "example-key"
  key_ring = google_kms_key_ring.example.id
}

resource "google_sql_ssl_cert" "example" {
  common_name = "example-cert"
  instance    = google_sql_database_instance.example.name
}

variable "aws_region" {
  type = string
}

variable "aws_vpc_id" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_client_id" {
  type = string
}

variable "azure_client_secret" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "azure_location" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_location" {
  type = string
}

variable "db_username" {
  type = string
}

variable "environment" {
  type = string
}

variable "allowed_cidr" {
  type = string
}