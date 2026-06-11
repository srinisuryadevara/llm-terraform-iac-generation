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
  }
}

resource "google_project_iam_binding" "spanner_instance_admin" {
  project = var.project_id
  role    = "roles/spanner.instanceAdmin"
  members = var.spanner_instance_admin_members
}

resource "google_project_iam_binding" "spanner_database_admin" {
  project = var.project_id
  role    = "roles/spanner.databaseAdmin"
  members = var.spanner_database_admin_members
}

resource "google_project_iam_binding" "spanner_database_reader" {
  project = var.project_id
  role    = "roles/spanner.databaseReader"
  members = var.spanner_database_reader_members
}

resource "google_project_iam_binding" "spanner_database_writer" {
  project = var.project_id
  role    = "roles/spanner.databaseWriter"
  members = var.spanner_database_writer_members
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

variable "spanner_instance_admin_members" {
  type = list(string)
}

variable "spanner_database_admin_members" {
  type = list(string)
}

variable "spanner_database_reader_members" {
  type = list(string)
}

variable "spanner_database_writer_members" {
  type = list(string)
}