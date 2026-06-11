# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

# Configure the GCP Provider
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# Create a random password for the database
resource "random_password" "password" {
  length = 16
  special = true
}

# AWS RDS Instance
resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t2.micro"
  name                 = "myrdsinstance"
  username             = "myuser"
  password             = random_password.password.result
  parameter_group_name = "default.postgres13"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

# AWS Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.rds_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AWS VPC for RDS
resource "aws_vpc" "rds_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Azure SQL Database
resource "azurerm_resource_group" "sql_rg" {
  name     = "sql-rg"
  location = var.azure_location
}

resource "azurerm_mssql_server" "sql_server" {
  name                = "myssqlserver"
  resource_group_name = azurerm_resource_group.sql_rg.name
  location            = azurerm_resource_group.sql_rg.location
  version             = "12.0"

  administrator_login          = "myadmin"
  administrator_login_password = random_password.password.result
}

resource "azurerm_mssql_database" "sql_database" {
  name        = "myssqldatabase"
  server_id   = azurerm_mssql_server.sql_server.id
  sku_name    = "S0"
  max_size_gb = 10
}

# GCP Cloud SQL Instance
resource "google_sql_database_instance" "sql_instance" {
  name                = "mysqlinstance"
  region              = var.gcp_region
  database_version   = "POSTGRES_13"
  deletion_protection = false

  settings {
    tier = "db-g1-small"
  }
}

resource "google_sql_user" "sql_user" {
  name     = "myuser"
  instance = google_sql_database_instance.sql_instance.name
  host     = "%"
  password = random_password.password.result
}