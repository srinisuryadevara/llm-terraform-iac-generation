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

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_name" {
  type = string
}

resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version        = "14.1"
  instance_class        = "db.t2.micro"
  name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot  = true
}

resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS instance"
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "azurerm_resource_group" "sql" {
  name     = "sql-rg"
  location = "West US"
}

resource "azurerm_sql_server" "sql" {
  name                = "sql-server"
  resource_group_name = azurerm_resource_group.sql.name
  location            = azurerm_resource_group.sql.location
  version             = "12.0"
  administrator_login          = var.db_username
  administrator_login_password = var.db_password
}

resource "azurerm_sql_database" "sql" {
  name                = var.db_name
  resource_group_name = azurerm_resource_group.sql.name
  server_name        = azurerm_sql_server.sql.name
  edition            = "Basic"
}

resource "google_sql_database_instance" "sql" {
  name                = "sql-instance"
  region              = var.gcp_region
  database_version = "POSTGRES_14"
  deletion_protection = false

  settings {
    tier = "db-g1-small"
  }
}

resource "google_sql_user" "sql" {
  name     = var.db_username
  instance = google_sql_database_instance.sql.name
  host     = "%"
  password = var.db_password
}

resource "google_sql_database" "sql" {
  name     = var.db_name
  instance = google_sql_database_instance.sql.name
}