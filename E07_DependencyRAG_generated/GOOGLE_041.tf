provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

resource "google_spanner_instance" "example" {
  name         = var.instance_name
  config       = var.instance_config
  display_name = var.instance_display_name
  num_nodes    = var.instance_num_nodes
}

resource "google_spanner_database" "example" {
  instance = google_spanner_instance.example.name
  name     = var.database_name
  ddl {
    database = google_spanner_database.example.name
    statements = [
      "CREATE TABLE example_table (id INT64, name STRING(1024)) PRIMARY KEY (id)",
    ]
  }
}

resource "google_project_iam_member" "spanner_instance_admin" {
  project = var.project_id
  role    = "roles/spanner.instanceAdmin"
  member  = var.spanner_instance_admin_member
}

resource "google_project_iam_member" "spanner_database_admin" {
  project = var.project_id
  role    = "roles/spanner.databaseAdmin"
  member  = var.spanner_database_admin_member
}

resource "google_project_iam_member" "spanner_database_reader" {
  project = var.project_id
  role    = "roles/spanner.databaseReader"
  member  = var.spanner_database_reader_member
}

resource "google_project_iam_member" "spanner_database_writer" {
  project = var.project_id
  role    = "roles/spanner.databaseWriter"
  member  = var.spanner_database_writer_member
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "instance_config" {
  type = string
}

variable "instance_display_name" {
  type = string
}

variable "instance_num_nodes" {
  type = number
}

variable "database_name" {
  type = string
}

variable "spanner_instance_admin_member" {
  type = string
}

variable "spanner_database_admin_member" {
  type = string
}

variable "spanner_database_reader_member" {
  type = string
}

variable "spanner_database_writer_member" {
  type = string
}