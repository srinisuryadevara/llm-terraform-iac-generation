# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module uses terraform 1.0 syntax and features that are available only since version 1.0.0.
# ----------------------------------------------------------------------------------------------------------------------
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

variable "aws_db_name" {
  default = "mydb"
}

variable "azure_location" {
  default = "West US"
}

variable "azure_resource_group_name" {}

variable "azure_sql_server_name" {}

variable "azure_sql_database_name" {
  default = "mydb"
}

variable "azure_sql_admin_login" {}

variable "azure_sql_admin_password" {}

variable "gcp_region" {
  default = "us-central1"
}

variable "gcp_project" {}

variable "gcp_sql_instance_name" {}

variable "gcp_sql_database_name" {
  default = "mydb"
}

variable "gcp_sql_username" {}

variable "gcp_sql_password" {}

# ----------------------------------------------------------------------------------------------------------------------
# PROVIDERS
# ----------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# ----------------------------------------------------------------------------------------------------------------------
# AWS RDS INSTANCE
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_db_instance" "example" {
  instance_class = var.aws_db_instance_class
  engine         = "postgres"
  username       = var.aws_db_username
  password       = var.aws_db_password
  db_name        = var.aws_db_name
}

# ----------------------------------------------------------------------------------------------------------------------
# AZURE SQL DATABASE
# ----------------------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "example" {
  name     = var.azure_resource_group_name
  location = var.azure_location
}

resource "azurerm_sql_server" "example" {
  name                = var.azure_sql_server_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"

  administrator_login          = var.azure_sql_admin_login
  administrator_login_password = var.azure_sql_admin_password
}

resource "azurerm_sql_database" "example" {
  name                = var.azure_sql_database_name
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_sql_server.example.name
  edition             = "Basic"
}

# ----------------------------------------------------------------------------------------------------------------------
# GCP CLOUD SQL INSTANCE
# ----------------------------------------------------------------------------------------------------------------------
resource "google_sql_database_instance" "example" {
  name                = var.gcp_sql_instance_name
  region              = var.gcp_region
  database_version   = "POSTGRES_13"
  deletion_protection = false
}

resource "google_sql_database" "example" {
  name     = var.gcp_sql_database_name
  instance = google_sql_database_instance.example.name
}

resource "google_sql_user" "example" {
  name     = var.gcp_sql_username
  instance = google_sql_database_instance.example.name
  host     = "%"
  password = var.gcp_sql_password
}