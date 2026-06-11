provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "database_version" {
  type = string
}

variable "database_tier" {
  type = string
}

variable "database_name" {
  type = string
}

variable "database_username" {
  type = string
}

variable "database_password" {
  type      = string
  sensitive = true
}

resource "google_sql_database_instance" "example" {
  name                = "example-sql-instance"
  region              = var.region
  database_version   = var.database_version
  deletion_protection = false

  settings {
    tier = var.database_tier
  }

  labels = {
    environment = "example"
    managed_by  = "terraform"
  }
}

resource "google_sql_database" "example" {
  name     = var.database_name
  instance = google_sql_database_instance.example.name

  labels = {
    environment = "example"
    managed_by  = "terraform"
  }
}

resource "google_sql_user" "example" {
  name     = var.database_username
  instance = google_sql_database_instance.example.name
  host     = "%"
  password = var.database_password

  labels = {
    environment = "example"
    managed_by  = "terraform"
  }
}

output "sql_instance_id" {
  value       = google_sql_database_instance.example.id
  description = "The ID of the Cloud SQL instance"
}

output "sql_instance_name" {
  value       = google_sql_database_instance.example.name
  description = "The name of the Cloud SQL instance"
}

output "sql_database_name" {
  value       = google_sql_database.example.name
  description = "The name of the Cloud SQL database"
}

output "sql_instance_public_ip_address" {
  value       = google_sql_database_instance.example.public_ip_address
  description = "The public IP address of the Cloud SQL instance"
}

output "sql_instance_private_ip_address" {
  value       = google_sql_database_instance.example.private_ip_address
  description = "The private IP address of the Cloud SQL instance"
}