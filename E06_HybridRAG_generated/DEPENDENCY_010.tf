variable "database_name" {}
variable "database_version" {
  default = "POSTGRES_14"
}
variable "database_region" {
  default = "us-central1"
}
variable "database_tier" {
  default = "db-n1-standard-1"
}

variable "database_username" {}
variable "database_password" {}

resource "google_sql_database_instance" "main" {
  name                = var.database_name
  region              = var.database_region
  database_version   = var.database_version
  deletion_protection = false

  settings {
    tier = var.database_tier
  }
}

resource "google_sql_database" "main" {
  name     = var.database_name
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "main" {
  name     = var.database_username
  instance = google_sql_database_instance.main.name
  host     = "%"
  password = var.database_password
}