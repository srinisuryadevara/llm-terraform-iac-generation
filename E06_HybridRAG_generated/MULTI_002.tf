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

variable "aws_instance_class" {
  default = "db.t2.micro"
}

variable "aws_database_name" {
  default = "mydb"
}

variable "aws_database_username" {
  default = "myuser"
}

variable "aws_database_password" {
  sensitive = true
}

variable "azure_location" {
  default = "West US"
}

variable "azure_database_name" {
  default = "mydb"
}

variable "azure_database_username" {
  default = "myuser"
}

variable "azure_database_password" {
  sensitive = true
}

variable "gcp_region" {
  default = "us-central1"
}

variable "gcp_database_name" {
  default = "mydb"
}

variable "gcp_database_username" {
  default = "myuser"
}

variable "gcp_database_password" {
  sensitive = true
}

# ----------------------------------------------------------------------------------------------------------------------
# PROVIDERS
# ----------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  version = "~>2.0"
  features {}
}

provider "google" {
  project = "myproject"
  region  = var.gcp_region
}

# ----------------------------------------------------------------------------------------------------------------------
# AWS RDS INSTANCE
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_db_instance" "example" {
  instance_class = var.aws_instance_class
  engine         = "postgres"
  name           = var.aws_database_name
  username       = var.aws_database_username
  password       = var.aws_database_password
}

# ----------------------------------------------------------------------------------------------------------------------
# AZURE SQL DATABASE
# ----------------------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = var.azure_location
}

resource "azurerm_sql_database" "example" {
  name                = var.azure_database_name
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  server_name         = azurerm_sql_server.example.name
}

resource "azurerm_sql_server" "example" {
  name                = "example-sql-server"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"

  administrator_login          = var.azure_database_username
  administrator_login_password = var.azure_database_password
}

# ----------------------------------------------------------------------------------------------------------------------
# GCP CLOUD SQL INSTANCE
# ----------------------------------------------------------------------------------------------------------------------
resource "google_sql_database_instance" "example" {
  name                = "example-sql-instance"
  region              = var.gcp_region
  database_version   = "POSTGRES_13"
  deletion_protection = false
}

resource "google_sql_database" "example" {
  name     = var.gcp_database_name
  instance = google_sql_database_instance.example.name
}

resource "google_sql_user" "example" {
  name     = var.gcp_database_username
  instance = google_sql_database_instance.example.name
  host     = "%"
  password = var.gcp_database_password
}