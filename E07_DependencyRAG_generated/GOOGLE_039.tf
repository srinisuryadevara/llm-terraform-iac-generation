provider "google" {
  project     = var.project_id
  region      = var.region
}

provider "google-beta" {
  project     = var.project_id
  region      = var.region
}

resource "google_spanner_instance" "example" {
  name          = var.instance_name
  config        = var.instance_config
  display_name  = var.instance_display_name
  num_nodes     = var.instance_num_nodes
}

resource "google_spanner_database" "example" {
  instance = google_spanner_instance.example.name
  name     = var.database_name
  ddl {
    database = google_spanner_database.example.name
  }
}

resource "google_project_iam_member" "spanner_admin" {
  project = var.project_id
  role    = "roles/spanner.admin"
  member  = var.spanner_admin_member
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
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region of the project"
}

variable "instance_name" {
  type        = string
  description = "The name of the Spanner instance"
}

variable "instance_config" {
  type        = string
  description = "The configuration of the Spanner instance"
}

variable "instance_display_name" {
  type        = string
  description = "The display name of the Spanner instance"
}

variable "instance_num_nodes" {
  type        = number
  description = "The number of nodes in the Spanner instance"
}

variable "database_name" {
  type        = string
  description = "The name of the Spanner database"
}

variable "spanner_admin_member" {
  type        = string
  description = "The member to be assigned the Spanner admin role"
}

variable "spanner_database_admin_member" {
  type        = string
  description = "The member to be assigned the Spanner database admin role"
}

variable "spanner_database_reader_member" {
  type        = string
  description = "The member to be assigned the Spanner database reader role"
}

variable "spanner_database_writer_member" {
  type        = string
  description = "The member to be assigned the Spanner database writer role"
}