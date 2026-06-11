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

# Create an AWS VPC for the AWS RDS instance
resource "aws_vpc" "rds" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name        = "rds-vpc"
    Environment = "dev"
  }
}

# Create a security group for the AWS RDS instance
resource "aws_security_group" "rds" {
  name        = "rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.rds.id
  tags = {
    Name        = "rds-sg"
    Environment = "dev"
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an AWS RDS instance
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
  tags = {
    Name        = "rds-instance"
    Environment = "dev"
  }
}

# Create an Azure Resource Group
resource "azurerm_resource_group" "sql" {
  name     = "myresourcegroup"
  location = var.azure_location
  tags = {
    Name        = "sql-rg"
    Environment = "dev"
  }
}

# Create an Azure SQL Server
resource "azurerm_sql_server" "sql" {
  name                         = "my-sql-server"
  resource_group_name          = azurerm_resource_group.sql.name
  location                     = azurerm_resource_group.sql.location
  version                      = "12.0"
  administrator_login          = "myadmin"
  administrator_login_password = random_password.password.result
  tags = {
    Name        = "sql-server"
    Environment = "dev"
  }
}

# Create an Azure SQL Database
resource "azurerm_sql_database" "sql" {
  name                = "my-sql-database"
  resource_group_name = azurerm_resource_group.sql.name
  location            = azurerm_resource_group.sql.location
  server_name         = azurerm_sql_server.sql.name
  edition              = "Basic"
  tags = {
    Name        = "sql-database"
    Environment = "dev"
  }
}

# Create a GCP Cloud SQL instance
resource "google_sql_database_instance" "sql" {
  name                = "my-cloud-sql-instance"
  region              = var.gcp_region
  database_version   = "POSTGRES_13"
  deletion_protection = false
  labels = {
    Name        = "cloud-sql-instance"
    Environment = "dev"
  }

  settings {
    tier = "db-g1-small"
  }
}

# Create a GCP Cloud SQL user
resource "google_sql_user" "sql" {
  name     = "myuser"
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

output "aws_rds_instance_id" {
  value = aws_db_instance.rds.id
}

output "aws_rds_instance_endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "azure_sql_server_id" {
  value = azurerm_sql_server.sql.id
}

output "azure_sql_database_id" {
  value = azurerm_sql_database.sql.id
}

output "gcp_cloud_sql_instance_id" {
  value = google_sql_database_instance.sql.id
}

output "gcp_cloud_sql_instance_connection_name" {
  value = google_sql_database_instance.sql.connection_name
}