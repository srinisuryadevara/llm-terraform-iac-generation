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
  default = "aws-rds-instance"
}

variable "aws_db_instance_class" {
  default = "db.t2.micro"
}

variable "aws_db_instance_engine" {
  default = "postgres"
}

variable "aws_db_instance_username" {
  default = "your-username"
}

variable "aws_db_instance_password" {
  default = "your-password"
}

variable "azurerm_sql_server_name" {
  default = "azurerm-sql-server"
}

variable "azurerm_sql_database_name" {
  default = "azurerm-sql-database"
}

variable "azurerm_sql_server_admin_login" {
  default = "your-username"
}

variable "azurerm_sql_server_admin_password" {
  default = "your-password"
}

variable "google_sql_database_instance_name" {
  default = "google-sql-instance"
}

variable "google_sql_database_name" {
  default = "google-sql-database"
}

variable "google_sql_database_username" {
  default = "your-username"
}

variable "google_sql_database_password" {
  default = "your-password"
}

# ----------------------------------------------------------------------------------------------------------------------
# AWS RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
resource "aws_db_subnet_group" "aws_db_subnet_group" {
  name       = "aws-rds-subnet-group"
  subnet_ids = [aws_subnet.aws_subnet.id]

  tags = {
    Name = "aws-rds-subnet-group"
  }
}

resource "aws_subnet" "aws_subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.aws_vpc.id
  availability_zone = "us-west-2a"

  tags = {
    Name = "aws-rds-subnet"
  }
}

resource "aws_vpc" "aws_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "aws-rds-vpc"
  }
}

resource "aws_security_group" "aws_security_group" {
  name        = "aws-rds-security-group"
  description = "Allow inbound traffic on port 5432"
  vpc_id      = aws_vpc.aws_vpc.id

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

  tags = {
    Name = "aws-rds-security-group"
  }
}

resource "aws_db_instance" "aws_db_instance" {
  identifier           = var.aws_db_instance_identifier
  instance_class       = var.aws_db_instance_class
  engine               = var.aws_db_instance_engine
  username             = var.aws_db_instance_username
  password             = var.aws_db_instance_password
  db_subnet_group_name = aws_db_subnet_group.aws_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.aws_security_group.id]
}

# ----------------------------------------------------------------------------------------------------------------------
# AZURE RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "azurerm_resource_group" {
  name     = "azurerm-sql-resource-group"
  location = "West US"
}

resource "azurerm_sql_server" "azurerm_sql_server" {
  name                = var.azurerm_sql_server_name
  resource_group_name = azurerm_resource_group.azurerm_resource_group.name
  location            = azurerm_resource_group.azurerm_resource_group.location
  version             = "12.0"

  administrator_login          = var.azurerm_sql_server_admin_login
  administrator_login_password = var.azurerm_sql_server_admin_password
}

resource "azurerm_sql_database" "azurerm_sql_database" {
  name                = var.azurerm_sql_database_name
  resource_group_name = azurerm_resource_group.azurerm_resource_group.name
  location            = azurerm_resource_group.azurerm_resource_group.location
  server_name         = azurerm_sql_server.azurerm_sql_server.name
  edition             = "Basic"
}

# ----------------------------------------------------------------------------------------------------------------------
# GCP RESOURCES
# ----------------------------------------------------------------------------------------------------------------------
resource "google_sql_database_instance" "google_sql_database_instance" {
  name                = var.google_sql_database_instance_name
  region              = "us-central1"
  database_version   = "POSTGRES_11"
  deletion_protection = false
}

resource "google_sql_database" "google_sql_database" {
  name     = var.google_sql_database_name
  instance = google_sql_database_instance.google_sql_database_instance.name
}

resource "google_sql_user" "google_sql_user" {
  name     = var.google_sql_database_username
  instance = google_sql_database_instance.google_sql_database_instance.name
  host     = "%"
  password = var.google_sql_database_password
}