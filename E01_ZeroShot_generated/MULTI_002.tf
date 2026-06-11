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

# Create a random password for database
resource "random_password" "password" {
  length = 16
  special = true
}

# Create AWS RDS instance
resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t2.micro"
  name                 = "myrdsdb"
  username             = "myuser"
  password             = random_password.password.result
  parameter_group_name = "default.postgres13"
  skip_final_snapshot  = true
}

# Create Azure SQL Database
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = var.azure_location
}

resource "azurerm_mssql_server" "example" {
  name                = "example-sql-server"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"

  administrator_login          = "adminuser"
  administrator_login_password = random_password.password.result
}

resource "azurerm_mssql_database" "example" {
  name        = "example-sql-db"
  server_id = azurerm_mssql_server.example.id
  sku_name   = "S0"
  max_size_gb = 10
}

# Create GCP Cloud SQL instance
resource "google_sql_database_instance" "example" {
  name                = "example-sql-instance"
  region              = var.gcp_region
  database_version = "POSTGRES_13"
  deletion_protection = false

  settings {
    tier = "db-g1-small"
  }
}

resource "google_sql_database" "example" {
  name     = "example-sql-db"
  instance = google_sql_database_instance.example.name
}

resource "google_sql_user" "example" {
  name     = "example-sql-user"
  instance = google_sql_database_instance.example.name
  host     = "%"
  password = random_password.password.result
}