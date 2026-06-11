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

variable "instance_id" {
  type = string
}

variable "database_id" {
  type = string
}

variable "spanner_instance_config" {
  type = string
}

resource "google_spanner_instance" "example" {
  name                = var.instance_id
  config              = var.spanner_instance_config
  display_name         = "Test Spanner Instance"
  num_nodes            = 1
}

resource "google_spanner_database" "example" {
  instance = google_spanner_instance.example.name
  name     = var.database_id
  ddl = [
    "CREATE TABLE Singers (SingerId INT64, FirstName STRING(1024), LastName STRING(1024))",
    "CREATE TABLE Albums (SingerId INT64, AlbumId INT64, AlbumTitle STRING(1024))",
  ]
}

resource "google_project_iam_binding" "spanner_database_admin" {
  project = var.project_id
  role    = "roles/spanner.databaseAdmin"

  members = [
    "user:admin@example.com",
  ]
}

resource "google_project_iam_binding" "spanner_database_reader" {
  project = var.project_id
  role    = "roles/spanner.databaseReader"

  members = [
    "user:reader@example.com",
  ]
}

resource "google_project_iam_binding" "spanner_database_writer" {
  project = var.project_id
  role    = "roles/spanner.databaseUser"

  members = [
    "user:writer@example.com",
  ]
}