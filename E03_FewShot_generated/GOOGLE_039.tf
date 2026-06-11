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
  default     = "us-central1"
}

variable "instance_id" {
  type        = string
}

variable "database_id" {
  type        = string
}

variable "spanner_instance_config" {
  type        = string
  default     = "regional-us-central1"
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
    "CREATE TABLE Singers (SingerId INT64, FirstName STRING(1024), LastName STRING(1024))",
    "CREATE TABLE Albums (SingerId INT64, AlbumId INT64, AlbumTitle STRING(1024))",
  ]
}

resource "google_project_iam_binding" "spanner_instance_admin" {
  project = var.project_id
  role    = "roles/spanner.instanceAdmin"
  members = [
    "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
  ]
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

resource "google_project_iam_binding" "spanner_database_writer" {
  project = var.project_id
  role    = "roles/spanner.databaseWriter"
  members = [
    "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
  ]
}