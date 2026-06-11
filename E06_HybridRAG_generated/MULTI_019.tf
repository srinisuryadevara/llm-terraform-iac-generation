#########################################################################################
# This configuration creates a managed relational database on AWS (RDS), Azure (SQL Database), and GCP (Cloud SQL)
#
# Follow the directions here to set up a Terraform service account in AWS
# https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-service.html
#
# Follow the directions here to set up a Terraform service principal in Azure
# https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal
#
# Follow the directions here to set up a Terraform service account in GCP
# https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
#
# Happy Terraforming!
#########################################################################################

###########################
# VARIABLES
############################

# AWS variables
variable "aws_region" {
  default = "us-west-2"
}
variable "aws_instance_class" {
  default = "db.t2.micro"
}
variable "aws_database_name" {}
variable "aws_database_username" {}
variable "aws_database_password" {}

# Azure variables
variable "azure_location" {
  default = "West US"
}
variable "azure_database_name" {}
variable "azure_database_username" {}
variable "azure_database_password" {}

# GCP variables
variable "gcp_region" {
  default = "us-central1"
}
variable "gcp_database_name" {}
variable "gcp_database_username" {}
variable "gcp_database_password" {}

############################
# PROVIDERS
############################

provider "aws" {
  version = "~> 3.0"
  region  = var.aws_region
}

provider "azurerm" {
  version = "~> 2.0"
  features {}
}

provider "google" {
  version = "~> 3.0"
  region  = var.gcp_region
}

############################
# RESOURCES
############################

# AWS RDS instance
resource "aws_db_instance" "example" {
  instance_class = var.aws_instance_class
  engine         = "postgres"
  name           = var.aws_database_name
  username       = var.aws_database_username
  password       = var.aws_database_password
}

# Azure SQL Database
resource "azurerm_sql_database" "example" {
  name                = var.azure_database_name
  resource_group_name = "example-resource-group"
  location            = var.azure_location
  server_name         = "example-sql-server"
}

resource "azurerm_sql_server" "example" {
  name                = "example-sql-server"
  resource_group_name = "example-resource-group"
  location            = var.azure_location
  version             = "12.0"
  administrator_login          = var.azure_database_username
  administrator_login_password = var.azure_database_password
}

# GCP Cloud SQL instance
resource "google_sql_database_instance" "example" {
  name                = "example-sql-instance"
  region              = var.gcp_region
  database_version   = "POSTGRES_13"
  deletion_protection = false
}

resource "google_sql_database" "example" {
  name     = var.gcp_database_name
  instance = google_sql_database_instance.example.name
}

resource "google_sql_user" "example" {
  name     = var.gcp_database_username
  instance = google_sql_database_instance.example.name
  host     = "%"
  password = var.gcp_database_password
}