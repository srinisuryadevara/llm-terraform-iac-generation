# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module uses terraform 1.0 syntax and features that are available only since version 1.0.0.
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.0.0"
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE AWS RDS INSTANCE
# ----------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  default     = "us-west-2"
}

variable "aws_db_instance_class" {
  type        = string
  default     = "db.t2.micro"
}

variable "aws_db_instance_identifier" {
  type        = string
}

variable "aws_db_username" {
  type        = string
  sensitive   = true
}

variable "aws_db_password" {
  type        = string
  sensitive   = true
}

resource "aws_db_instance" "rds_instance" {
  instance_class = var.aws_db_instance_class
  identifier     = var.aws_db_instance_identifier
  engine         = "postgres"
  username       = var.aws_db_username
  password       = var.aws_db_password
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE AZURE SQL DATABASE
# ----------------------------------------------------------------------------------------------------------------------
provider "azurerm" {
  version = "~>3.47.0"
  features {}
}

variable "azure_location" {
  type        = string
  default     = "West US"
}

variable "azure_resource_group_name" {
  type        = string
}

variable "azure_sql_server_name" {
  type        = string
}

variable "azure_sql_database_name" {
  type        = string
}

variable "azure_sql_admin_username" {
  type        = string
  sensitive   = true
}

variable "azure_sql_admin_password" {
  type        = string
  sensitive   = true
}

resource "azurerm_resource_group" "resource_group" {
  name     = var.azure_resource_group_name
  location = var.azure_location
}

resource "azurerm_mssql_server" "sql_server" {
  name                = var.azure_sql_server_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  version             = "12.0"

  administrator_login          = var.azure_sql_admin_username
  administrator_login_password = var.azure_sql_admin_password
}

resource "azurerm_mssql_database" "sql_database" {
  name        = var.azure_sql_database_name
  server_id   = azurerm_mssql_server.sql_server.id
  sku_name    = "S0"
  max_size_gb = 10
}

# ----------------------------------------------------------------------------------------------------------------------
# CREATE GCP CLOUD SQL INSTANCE
# ----------------------------------------------------------------------------------------------------------------------
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

variable "gcp_project" {
  type        = string
}

variable "gcp_region" {
  type        = string
  default     = "us-central1"
}

variable "gcp_cloud_sql_instance_name" {
  type        = string
}

variable "gcp_cloud_sql_database_name" {
  type        = string
}

variable "gcp_cloud_sql_username" {
  type        = string
  sensitive   = true
}

variable "gcp_cloud_sql_password" {
  type        = string
  sensitive   = true
}

resource "google_sql_database_instance" "cloud_sql_instance" {
  name                = var.gcp_cloud_sql_instance_name
  region              = var.gcp_region
  database_version   = "POSTGRES_13"
  deletion_protection = false
}

resource "google_sql_database" "cloud_sql_database" {
  name     = var.gcp_cloud_sql_database_name
  instance = google_sql_database_instance.cloud_sql_instance.name
}

resource "google_sql_user" "cloud_sql_user" {
  name     = var.gcp_cloud_sql_username
  instance = google_sql_database_instance.cloud_sql_instance.name
  password = var.gcp_cloud_sql_password
}