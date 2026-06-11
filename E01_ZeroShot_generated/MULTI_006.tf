# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# AWS RDS
resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t2.micro"
  name                 = "myrds"
  username             = var.aws_rds_username
  password             = var.aws_rds_password
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot  = true
}

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Allow inbound traffic on port 5432"
  vpc_id      = var.aws_vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Azure SQL Database
resource "azurerm_resource_group" "sql" {
  name     = "my-sql-rg"
  location = var.azure_location
}

resource "azurerm_sql_server" "sql" {
  name                = "my-sql-server"
  resource_group_name = azurerm_resource_group.sql.name
  location            = azurerm_resource_group.sql.location
  version             = "12.0"
  administrator_login          = var.azure_sql_username
  administrator_login_password = var.azure_sql_password
}

resource "azurerm_sql_database" "sql" {
  name                = "my-sql-db"
  resource_group_name = azurerm_resource_group.sql.name
  server_name         = azurerm_sql_server.sql.name
  edition             = "Basic"
}

# GCP Cloud SQL
resource "google_sql_database_instance" "sql" {
  name                = "my-sql-instance"
  region              = var.gcp_region
  database_version = "POSTGRES_13"
  deletion_protection = false

  settings {
    tier = "db-g1-small"
  }
}

resource "google_sql_user" "sql" {
  name     = var.gcp_sql_username
  instance = google_sql_database_instance.sql.name
  host     = "%"
  password = var.gcp_sql_password
}

variable "aws_region" {
  type = string
}

variable "aws_rds_username" {
  type = string
}

variable "aws_rds_password" {
  type = string
}

variable "aws_vpc_id" {
  type = string
}

variable "azure_location" {
  type = string
}

variable "azure_sql_username" {
  type = string
}

variable "azure_sql_password" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_sql_username" {
  type = string
}

variable "gcp_sql_password" {
  type = string
}