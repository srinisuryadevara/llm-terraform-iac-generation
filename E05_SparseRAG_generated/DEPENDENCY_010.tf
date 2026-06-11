variable "project" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region of the Cloud SQL instance"
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

variable "instance_name" {
  type        = string
  description = "The name of the Cloud SQL instance"
}

resource "google_sql_database_instance" "camunda-db" {
  name                = var.instance_name
  region              = var.region
  database_version   = "POSTGRES_14"
  deletion_protection = false
}

resource "google_sql_database" "database" {
  name     = var.database_name
  instance = google_sql_database_instance.camunda-db.name
}

resource "google_sql_user" "user" {
  name     = var.database_username
  instance = google_sql_database_instance.camunda-db.name
  host     = "%"
  password = var.database_password
}