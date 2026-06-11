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
resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t2.micro"
  name                 = "myrdsdb"
  username             = "myuser"
  password             = random_password.password.result
  parameter_group_name = "default.postgres13"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds.id]
}

# AWS Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.rds.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AWS VPC for RDS
resource "aws_vpc" "rds" {
  cidr_block = "10.0.0.0/16"
}

# Azure SQL Database
resource "azurerm_resource_group" "sql" {
  name     = "myresourcegroup"
  location = var.azure_location
}

resource "azurerm_sql_server" "sql" {
  name                = "myssqlserver"
  resource_group_name = azurerm_resource_group.sql.name
  location            = azurerm_resource_group.sql.location
  version             = "12.0"

  administrator_login          = "myadmin"
  administrator_login_password = random_password.password.result
}

resource "azurerm_sql_database" "sql" {
  name                = "myssqldb"
  resource_group_name = azurerm_resource_group.sql.name
  server_name         = azurerm_sql_server.sql.name
  edition             = "Basic"
  collation           = "SQL_Latin1_General_CP1_CI_AS"
}

# GCP Cloud SQL Instance
resource "google_sql_database_instance" "sql" {
  name                = "mygcpinstance"
  region              = var.gcp_region
  database_version   = "POSTGRES_13"
  deletion_protection = false

  settings {
    tier = "db-g1-small"
  }
}

resource "google_sql_user" "sql" {
  name     = "mygcpuser"
  instance = google_sql_database_instance.sql.name
  host     = "%"
  password = random_password.password.result
}

variable "aws_region" {
  type = string
}

variable "azure_subscription_id" {
  type = string
}

variable "azure_client_id" {
  type = string
}

variable "azure_client_secret" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "azure_location" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}