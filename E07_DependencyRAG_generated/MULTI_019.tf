# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module uses terraform 0.12 syntax and features that are available only since version 0.12.7, however
# we now depend on a bug fix released in 0.12.7.
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12.7"
}

# ----------------------------------------------------------------------------------------------------------------------
# PROVIDERS
# ----------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = "us-west-2"
}

provider "azurerm" {
  version = "~>3.47.0"
  features {}
}

provider "google" {
  project = "your-project-id"
  region  = "us-central1"
}

# ----------------------------------------------------------------------------------------------------------------------
# VARIABLES
# ----------------------------------------------------------------------------------------------------------------------
variable "aws_db_instance_identifier" {
  type        = string
  default     = "aws-rds-instance"
}

variable "aws_db_instance_class" {
  type        = string
  default     = "db.t2.micro"
}

variable "aws_db_instance_engine" {
  type        = string
  default     = "postgres"
}

variable "aws_db_instance_username" {
  type        = string
  sensitive   = true
}

variable "aws_db_instance_password" {
  type        = string
  sensitive   = true
}

variable "azurerm_sql_server_name" {
  type        = string
  default     = "azurerm-sql-server"
}

variable "azurerm_sql_database_name" {
  type        = string
  default     = "azurerm-sql-database"
}

variable "azurerm_sql_server_admin_login" {
  type        = string
  sensitive   = true
}

variable "azurerm_sql_server_admin_password" {
  type        = string
  sensitive   = true
}

variable "google_sql_database_instance_name" {
  type        = string
  default     = "google-sql-instance"
}

variable "google_sql_database_name" {
  type        = string
  default     = "google-sql-database"
}

variable "google_sql_database_username" {
  type        = string
  sensitive   = true
}

variable "google_sql_database_password" {
  type        = string
  sensitive   = true
}

# ----------------------------------------------------------------------------------------------------------------------
# AWS RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "aws-rds-subnet-group"
  subnet_ids = [aws_subnet.db_subnet.id]
}

resource "aws_subnet" "db_subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.vpc.id
  availability_zone = "us-west-2a"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_security_group" "db_security_group" {
  name        = "aws-rds-security-group"
  description = "Allow inbound traffic on port 5432"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "db_instance" {
  identifier           = var.aws_db_instance_identifier
  instance_class       = var.aws_db_instance_class
  engine               = var.aws_db_instance_engine
  username             = var.aws_db_instance_username
  password             = var.aws_db_instance_password
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
}

# ----------------------------------------------------------------------------------------------------------------------
# AZURE RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "resource_group" {
  name     = "azurerm-resource-group"
  location = "West US"
}

resource "azurerm_sql_server" "sql_server" {
  name                = var.azurerm_sql_server_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  version             = "12.0"

  administrator_login          = var.azurerm_sql_server_admin_login
  administrator_login_password = var.azurerm_sql_server_admin_password
}

resource "azurerm_sql_database" "sql_database" {
  name                = var.azurerm_sql_database_name
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  server_name         = azurerm_sql_server.sql_server.name
  edition             = "Basic"
}

# ----------------------------------------------------------------------------------------------------------------------
# GCP RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
resource "google_sql_database_instance" "sql_instance" {
  name                = var.google_sql_database_instance_name
  region              = "us-central1"
  database_version   = "POSTGRES_11"
  deletion_protection = false

  settings {
    tier = "db-n1-standard-1"
  }
}

resource "google_sql_database" "sql_database" {
  name     = var.google_sql_database_name
  instance = google_sql_database_instance.sql_instance.name
}

resource "google_sql_user" "sql_user" {
  name     = var.google_sql_database_username
  instance = google_sql_database_instance.sql_instance.name
  host     = "%"
  password = var.google_sql_database_password
}