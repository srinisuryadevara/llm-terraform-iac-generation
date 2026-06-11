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

variable "aws_region" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "database_username" {
  type = string
}

variable "database_password" {
  type = string
  sensitive = true
}

variable "database_name" {
  type = string
}

resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version        = "8.0.28"
  instance_class       = "db.t2.micro"
  name                 = var.database_name
  username             = var.database_username
  password             = var.database_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot = true
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_mssql_server" "example" {
  name                = "example-sql-server"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  version             = "12.0"

  administrator_login          = var.database_username
  administrator_login_password = var.database_password
}

resource "azurerm_mssql_database" "example" {
  name        = var.database_name
  server_id = azurerm_mssql_server.example.id
  sku_name   = "S0"
}

resource "google_sql_database_instance" "example" {
  name                = "example-sql-instance"
  region              = var.gcp_region
  database_version    = "MYSQL_8_0"
  deletion_protection = false

  settings {
    tier = "db-n1-standard-1"
  }
}

resource "google_sql_database" "example" {
  name     = var.database_name
  instance = google_sql_database_instance.example.name
}

resource "google_sql_user" "example" {
  name     = var.database_username
  instance = google_sql_database_instance.example.name
  host     = "%"
  password = var.database_password
}