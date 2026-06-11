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

variable "database_instance_name" {
  type = string
}

variable "database_version" {
  type = string
}

variable "database_tier" {
  type = string
}

variable "database_availability_type" {
  type = string
}

resource "google_sql_database_instance" "main" {
  name                = var.database_instance_name
  database_version    = var.database_version
  tier                = var.database_tier
  availability_type   = var.database_availability_type
  deletion_protection = false
}

resource "google_sql_database" "main" {
  name     = "main"
  instance = google_sql_database_instance.main.name
}