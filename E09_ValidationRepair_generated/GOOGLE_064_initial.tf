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
  display_name        = "Example Spanner Instance"
  num_nodes           = 1
  force_destroy       = true
}

resource "google_spanner_database" "example" {
  instance = google_spanner_instance.example.name
  name     = var.database_id
  ddl {
    database = var.database_id
  }
}

resource "google_project_iam_member" "spanner_admin" {
  project = var.project_id
  role    = "roles/spanner.admin"
  member  = "user:${var.spanner_admin_user}"
}

resource "google_project_iam_member" "spanner_database_admin" {
  project = var.project_id
  role    = "roles/spanner.databaseAdmin"
  member  = "user:${var.spanner_database_admin_user}"
}

resource "google_project_iam_member" "spanner_database_reader" {
  project = var.project_id
  role    = "roles/spanner.databaseReader"
  member  = "user:${var.spanner_database_reader_user}"
}

resource "google_project_iam_member" "spanner_database_writer" {
  project = var.project_id
  role    = "roles/spanner.databaseWriter"
  member  = "user:${var.spanner_database_writer_user}"
}

variable "spanner_admin_user" {
  type = string
}

variable "spanner_database_admin_user" {
  type = string
}

variable "spanner_database_reader_user" {
  type = string
}

variable "spanner_database_writer_user" {
  type = string
}