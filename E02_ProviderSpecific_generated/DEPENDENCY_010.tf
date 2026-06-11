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

resource "google_sql_database_instance" "main" {
  database_version = var.database_version
  region           = var.region
  tier             = var.database_tier
}

resource "google_sql_database" "main" {
  name     = var.database_name
  instance = google_sql_database_instance.main.id
}

resource "google_sql_user" "main" {
  name     = var.database_username
  instance = google_sql_database_instance.main.id
  password = var.database_password
}