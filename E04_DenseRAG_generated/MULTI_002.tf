terraform {
  required_version = ">= 1.0.0"
}

# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES
# ----------------------------------------------------------------------------------------------------------------------
variable "aws_region" {
  default = "us-west-2"
}

variable "aws_db_instance_class" {
  default = "db.t2.micro"
}

variable "aws_db_username" {}
variable "aws_db_password" {}

variable "azure_region" {
  default = "West US"
}

variable "azure_resource_group_name" {}
variable "azure_sql_server_name" {}
variable "azure_sql_database_name" {}
variable "azure_sql_admin_username" {}
variable "azure_sql_admin_password" {}

variable "gcp_region" {
  default = "us-central1"
}

variable "gcp_project_id" {}
variable "gcp_database_instance_name" {}
variable "gcp_database_name" {}
variable "gcp_database_username" {}
variable "gcp_database_password" {}

# ----------------------------------------------------------------------------------------------------------------------
# PROVIDERS
# ----------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  version = "~>3.47.0"
  features {}
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# ----------------------------------------------------------------------------------------------------------------------
# AWS RDS INSTANCE
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_db_instance" "rds_instance" {
  instance_class = var.aws_db_instance_class
  engine         = "postgres"
  username       = var.aws_db_username
  password       = var.aws_db_password
  publicly_accessible = true
}

# ----------------------------------------------------------------------------------------------------------------------
# AZURE SQL DATABASE
# ----------------------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "resource_group" {
  name     = var.azure_resource_group_name
  location = var.azure_region
}

resource "azurerm_sql_server" "sql_server" {
  name                = var.azure_sql_server_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  version             = "12.0"

  administrator_login          = var.azure_sql_admin_username
  administrator_login_password = var.azure_sql_admin_password
}

resource "azurerm_sql_database" "sql_database" {
  name                = var.azure_sql_database_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  server_name         = azurerm_sql_server.sql_server.name
  edition             = "Basic"
}

# ----------------------------------------------------------------------------------------------------------------------
# GCP CLOUD SQL INSTANCE
# ----------------------------------------------------------------------------------------------------------------------
resource "google_sql_database_instance" "sql_instance" {
  name                = var.gcp_database_instance_name
  region              = var.gcp_region
  database_version   = "POSTGRES_14"
  deletion_protection = false
}

resource "google_sql_database" "sql_database" {
  name     = var.gcp_database_name
  instance = google_sql_database_instance.sql_instance.name
}

resource "google_sql_user" "sql_user" {
  name     = var.gcp_database_username
  instance = google_sql_database_instance.sql_instance.name
  password = var.gcp_database_password
}