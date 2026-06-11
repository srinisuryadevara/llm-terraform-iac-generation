provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t2.micro"
  name                 = "myrdsinstance"
  username             = var.aws_rds_username
  password             = var.aws_rds_password
  parameter_group_name = "default.postgres13"
  skip_final_snapshot  = true
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_sql_database" "example" {
  name                = "example_db"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  server_name          = azurerm_mssql_server.example.name
}

resource "azurerm_mssql_server" "example" {
  name                = "example-sql-server"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"
  administrator_login          = var.azure_sql_username
  administrator_login_password = var.azure_sql_password
}

resource "google_sql_database_instance" "example" {
  name                = "example-sql-instance"
  region              = var.gcp_region
  database_version   = "POSTGRES_13"
  deletion_protection = false

  settings {
    tier = "db-g1-small"
  }
}

resource "google_sql_database" "example" {
  name     = "example-db"
  instance = google_sql_database_instance.example.name
}

resource "google_sql_user" "example" {
  name     = var.gcp_sql_username
  instance = google_sql_database_instance.example.name
  host     = "%"
  password = var.gcp_sql_password
}