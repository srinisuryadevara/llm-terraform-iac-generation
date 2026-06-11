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

# AWS RDS Instance
resource "aws_db_instance" "example" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t2.micro"
  name                 = "exampledb"
  username             = var.aws_rds_username
  password             = var.aws_rds_password
  parameter_group_name = "default.postgres13"
  skip_final_snapshot  = true
}

# Azure SQL Database
resource "azurerm_resource_group" "example" {
  name     = "example-resource-group"
  location = var.azure_location
}

resource "azurerm_sql_server" "example" {
  name                = "example-sql-server"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"

  administrator_login          = var.azure_sql_username
  administrator_login_password = var.azure_sql_password
}

resource "azurerm_sql_database" "example" {
  name                = "example-sql-database"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  server_name         = azurerm_sql_server.example.name
  edition             = "Basic"
}

# GCP Cloud SQL Instance
resource "google_sql_database_instance" "example" {
  name                = "example-sql-instance"
  region              = var.gcp_region
  database_version   = "POSTGRES_13"
  deletion_protection = false

  settings {
    tier = "db-g1-small"
  }
}

resource "google_sql_user" "example" {
  name     = var.gcp_sql_username
  instance = google_sql_database_instance.example.name
  host     = "%"
  password = var.gcp_sql_password
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "aws_rds_username" {
  type        = string
  sensitive   = true
}

variable "aws_rds_password" {
  type        = string
  sensitive   = true
}

variable "azure_location" {
  type        = string
  sensitive   = true
}

variable "azure_sql_username" {
  type        = string
  sensitive   = true
}

variable "azure_sql_password" {
  type        = string
  sensitive   = true
}

variable "gcp_project" {
  type        = string
  sensitive   = true
}

variable "gcp_region" {
  type        = string
  sensitive   = true
}

variable "gcp_sql_username" {
  type        = string
  sensitive   = true
}

variable "gcp_sql_password" {
  type        = string
  sensitive   = true
}