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

variable "spanner_instance_nodes" {
  type = number
}

resource "google_spanner_instance" "example" {
  name                = var.instance_id
  config              = var.spanner_instance_config
  display_name        = "Example Spanner Instance"
  num_nodes           = var.spanner_instance_nodes
  force_destroy       = true
}

resource "google_spanner_database" "example" {
  instance = google_spanner_instance.example.name
  name     = var.database_id
  ddl {
    database = var.database_id
    statements = [
      "CREATE TABLE Singers (SingerId INT64, FirstName STRING(1024), LastName STRING(1024), BirthDate DATE) PRIMARY KEY (SingerId)",
    ]
  }
}

resource "google_project_iam_binding" "spanner_database_admin" {
  project = var.project_id
  role    = "roles/spanner.databaseAdmin"
  members = [
    "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
  ]
}

resource "google_project_iam_binding" "spanner_database_reader" {
  project = var.project_id
  role    = "roles/spanner.databaseReader"
  members = [
    "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
  ]
}

resource "google_project_iam_binding" "spanner_instance_admin" {
  project = var.project_id
  role    = "roles/spanner.instanceAdmin"
  members = [
    "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
  ]
}

resource "google_project_iam_binding" "spanner_instance_reader" {
  project = var.project_id
  role    = "roles/spanner.instanceReader"
  members = [
    "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
  ]
}