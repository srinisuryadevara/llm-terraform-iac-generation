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