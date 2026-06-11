provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "instance_id" {
  type        = string
  sensitive   = true
}

variable "database_id" {
  type        = string
  sensitive   = true
}

variable "spanner_instance_config" {
  type        = string
  sensitive   = true
}

resource "google_spanner_instance" "example" {
  name                = var.instance_id
  config              = var.spanner_instance_config
  display_name        = "Example Spanner Instance"
  num_nodes           = 1
}

resource "google_spanner_database" "example" {
  instance           = google_spanner_instance.example.name
  name               = var.database_id
  ddl                = [
    "CREATE TABLE example_table (id INT64, name STRING(1024)) PRIMARY KEY (id)",
  ]
}

resource "google_project_iam_member" "spanner_instance_user" {
  project = var.project_id
  role    = "roles/spanner.databaseUser"
  member  = "user:${var.spanner_instance_user}"
}

resource "google_project_iam_member" "spanner_instance_admin" {
  project = var.project_id
  role    = "roles/spanner.admin"
  member  = "user:${var.spanner_instance_admin}"
}

variable "spanner_instance_user" {
  type        = string
  sensitive   = true
}

variable "spanner_instance_admin" {
  type        = string
  sensitive   = true
}