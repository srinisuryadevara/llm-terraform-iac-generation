variable "project" {
  type        = string
  description = "The ID of the project to create the resources in"
}

variable "region" {
  type        = string
  description = "The region to create the resources in"
}

variable "database_instance_name" {
  type        = string
  description = "The name of the Cloud SQL database instance"
}

variable "database_name" {
  type        = string
  description = "The name of the database"
}

variable "database_username" {
  type        = string
  description = "The username for the database"
}

variable "database_password" {
  type        = string
  sensitive   = true
  description = "The password for the database"
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_sql_database_instance" "example" {
  name                = var.database_instance_name
  region              = var.region
  database_version   = "POSTGRES_14"
  deletion_protection = false
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