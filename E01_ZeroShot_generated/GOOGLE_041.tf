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
  display_name         = "Example Spanner Instance"
  num_nodes            = 1
  processing_units    = 1
}

resource "google_spanner_database" "example" {
  instance = google_spanner_instance.example.name
  name     = var.database_id
  ddl = [
    "CREATE TABLE example_table (id INT64, name STRING(1024))",
  ]
}

resource "google_spanner_database_iam_member" "example" {
  database = google_spanner_database.example.name
  role     = "roles/spanner.databaseReader"
  member   = "user:example-user@example.com"
}

resource "google_spanner_instance_iam_member" "example" {
  instance = google_spanner_instance.example.name
  role     = "roles/spanner.instanceUser"
  member   = "user:example-user@example.com"
}