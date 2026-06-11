# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module uses terraform 1.0 syntax and features that are available only since version 1.0.0.
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.0.0"
}

# ----------------------------------------------------------------------------------------------------------------------
# PROVIDERS
# ----------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  version = "~> 3.47.0"
  features {}
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES
# ----------------------------------------------------------------------------------------------------------------------
variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_instance_class" {
  type        = string
  description = "AWS RDS Instance Class"
}

variable "aws_database_name" {
  type        = string
  description = "AWS RDS Database Name"
}

variable "aws_database_username" {
  type        = string
  description = "AWS RDS Database Username"
}

variable "aws_database_password" {
  type        = string
  description = "AWS RDS Database Password"
  sensitive   = true
}

variable "azurerm_resource_group_name" {
  type        = string
  description = "Azure Resource Group Name"
}

variable "azurerm_sql_server_name" {
  type        = string
  description = "Azure SQL Server Name"
}

variable "azurerm_sql_database_name" {
  type        = string
  description = "Azure SQL Database Name"
}

variable "azurerm_sql_admin_username" {
  type        = string
  description = "Azure SQL Admin Username"
}

variable "azurerm_sql_admin_password" {
  type        = string
  description = "Azure SQL Admin Password"
  sensitive   = true
}

variable "gcp_project" {
  type        = string
  description = "GCP Project ID"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}

variable "gcp_instance_name" {
  type        = string
  description = "GCP Cloud SQL Instance Name"
}

variable "gcp_database_name" {
  type        = string
  description = "GCP Cloud SQL Database Name"
}

variable "gcp_database_username" {
  type        = string
  description = "GCP Cloud SQL Database Username"
}

variable "gcp_database_password" {
  type        = string
  description = "GCP Cloud SQL Database Password"
  sensitive   = true
}

# ----------------------------------------------------------------------------------------------------------------------
# AWS RDS INSTANCE
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_db_instance" "rds_instance" {
  instance_class = var.aws_instance_class
  engine         = "postgres"
  name           = var.aws_database_name
  username       = var.aws_database_username
  password       = var.aws_database_password
}

# ----------------------------------------------------------------------------------------------------------------------
# AZURE SQL DATABASE
# ----------------------------------------------------------------------------------------------------------------------
resource "azurerm_sql_server" "sql_server" {
  name                = var.azurerm_sql_server_name
  resource_group_name = var.azurerm_resource_group_name
  location            = var.azurerm_resource_group_name
  version             = "12.0"

  administrator_login          = var.azurerm_sql_admin_username
  administrator_login_password = var.azurerm_sql_admin_password
}

resource "azurerm_sql_database" "sql_database" {
  name                = var.azurerm_sql_database_name
  resource_group_name = var.azurerm_resource_group_name
  server_name         = var.azurerm_sql_server_name
  edition             = "Basic"
}

# ----------------------------------------------------------------------------------------------------------------------
# GCP CLOUD SQL INSTANCE
# ----------------------------------------------------------------------------------------------------------------------
resource "google_sql_database_instance" "sql_instance" {
  name                = var.gcp_instance_name
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
  host     = "%"
  password = var.gcp_database_password
}