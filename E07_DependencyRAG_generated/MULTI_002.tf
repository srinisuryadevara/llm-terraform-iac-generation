# AWS RDS
provider "aws" {
  region = "us-west-2"
}

variable "aws_db_instance_identifier" {
  type = string
}

variable "aws_db_instance_class" {
  type = string
}

variable "aws_db_instance_engine" {
  type = string
}

variable "aws_db_instance_username" {
  type = string
  sensitive = true
}

variable "aws_db_instance_password" {
  type = string
  sensitive = true
}

variable "aws_db_instance_database_name" {
  type = string
}

variable "aws_vpc_id" {
  type = string
}

variable "aws_subnet_ids" {
  type = list(string)
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = var.aws_subnet_ids
}

resource "aws_security_group" "rds_security_group" {
  name        = "rds-security-group"
  description = "Allow inbound traffic on port 5432"
  vpc_id      = var.aws_vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "rds_instance" {
  identifier           = var.aws_db_instance_identifier
  instance_class       = var.aws_db_instance_class
  engine               = var.aws_db_instance_engine
  username             = var.aws_db_instance_username
  password             = var.aws_db_instance_password
  database_name        = var.aws_db_instance_database_name
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
}

# Azure SQL Database
provider "azurerm" {
  version = "~>3.47.0"
  features {}
}

variable "azurerm_resource_group_name" {
  type = string
}

variable "azurerm_location" {
  type = string
}

variable "azurerm_sql_server_name" {
  type = string
}

variable "azurerm_sql_server_admin_login" {
  type = string
  sensitive = true
}

variable "azurerm_sql_server_admin_password" {
  type = string
  sensitive = true
}

variable "azurerm_sql_database_name" {
  type = string
}

resource "azurerm_resource_group" "sql_resource_group" {
  name     = var.azurerm_resource_group_name
  location = var.azurerm_location
}

resource "azurerm_sql_server" "sql_server" {
  name                = var.azurerm_sql_server_name
  resource_group_name = azurerm_resource_group.sql_resource_group.name
  location            = azurerm_resource_group.sql_resource_group.location
  version             = "12.0"

  administrator_login          = var.azurerm_sql_server_admin_login
  administrator_login_password = var.azurerm_sql_server_admin_password
}

resource "azurerm_sql_database" "sql_database" {
  name                = var.azurerm_sql_database_name
  resource_group_name = azurerm_resource_group.sql_resource_group.name
  location            = azurerm_resource_group.sql_resource_group.location
  server_name         = azurerm_sql_server.sql_server.name
  edition             = "Standard"
}

# GCP Cloud SQL
provider "google" {
  project = "your-project-id"
  region  = "us-central1"
}

variable "gcp_sql_instance_name" {
  type = string
}

variable "gcp_sql_database_name" {
  type = string
}

variable "gcp_sql_instance_tier" {
  type = string
}

variable "gcp_sql_instance_availability_type" {
  type = string
}

variable "gcp_sql_instance_database_version" {
  type = string
}

variable "gcp_sql_instance_username" {
  type = string
  sensitive = true
}

variable "gcp_sql_instance_password" {
  type = string
  sensitive = true
}

resource "google_sql_database_instance" "sql_instance" {
  name                = var.gcp_sql_instance_name
  database_version   = var.gcp_sql_instance_database_version
  region              = "us-central1"
  deletion_protection = false

  settings {
    tier = var.gcp_sql_instance_tier
    availability_type = var.gcp_sql_instance_availability_type
  }
}

resource "google_sql_database" "sql_database" {
  name     = var.gcp_sql_database_name
  instance = google_sql_database_instance.sql_instance.name
}

resource "google_sql_user" "sql_user" {
  name     = var.gcp_sql_instance_username
  instance = google_sql_database_instance.sql_instance.name
  host     = "%"
  password = var.gcp_sql_instance_password
}