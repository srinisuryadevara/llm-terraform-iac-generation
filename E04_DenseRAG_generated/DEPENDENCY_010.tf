terraform {
  required_version = ">= 0.12"
}

variable "project_id" {}
variable "region" {
  default = "us-central1"
}
variable "database_version" {
  default = "POSTGRES_13"
}
variable "database_tier" {
  default = "db-n1-standard-1"
}
variable "database_availability_type" {
  default = "REGIONAL"
}
variable "database_disk_size" {
  default = 50
}
variable "database_disk_type" {
  default = "PD_SSD"
}
variable "database_user_name" {
  default = "postgres"
}
variable "database_user_password" {}

provider "google" {
  version = "~> 4.0"
  region  = var.region
  project = var.project_id
}

resource "google_sql_database_instance" "main" {
  name                = "main-database-instance"
  region              = var.region
  database_version   = var.database_version
  deletion_protection = false

  settings {
    tier              = var.database_tier
    availability_type = var.database_availability_type
    disk_size         = var.database_disk_size
    disk_type         = var.database_disk_type

    ip_configuration {
      ipv4_enabled = true
    }
  }
}

resource "google_sql_database" "main" {
  name     = "main-database"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "main" {
  name     = var.database_user_name
  instance = google_sql_database_instance.main.name
  host     = "%"
  password = var.database_user_password
}