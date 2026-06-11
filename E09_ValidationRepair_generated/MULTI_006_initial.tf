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

# Create a random password for database
resource "random_password" "password" {
  length = 16
  special = true
}

# AWS RDS
resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t2.micro"
  name                 = "myrdsdb"
  username             = var.aws_rds_username
  password             = random_password.password.result
  parameter_group_name = "default.postgres13"
  skip_final_snapshot  = true
}

# Azure SQL Database
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = var.azure_location
}

resource "azurerm_sql_database" "example" {
  name                = "myazuresqldb"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  server_name         = azurerm_mssql_server.example.name
}

resource "azurerm_mssql_server" "example" {
  name                = "myazuresqlserver"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"

  administrator_login          = var.azure_sql_username
  administrator_login_password = random_password.password.result
}

# GCP Cloud SQL
resource "google_sql_database_instance" "example" {
  name                = "mygcpdb"
  region              = var.gcp_region
  database_version   = "POSTGRES_13"
  deletion_protection = false

  settings {
    tier = "db-g1-small"
  }
}

resource "google_sql_user" "users" {
  name     = var.gcp_sql_username
  instance = google_sql_database_instance.example.name
  host     = "%"
  password = random_password.password.result
}

variable "aws_region" {
  type        = string
  sensitive   = true
}

variable "aws_rds_username" {
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