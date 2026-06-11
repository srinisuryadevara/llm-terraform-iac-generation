# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Define input variables
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

# Create a Google Cloud Spanner instance
resource "google_spanner_instance" "example" {
  name                = var.instance_id
  config              = var.spanner_instance_config
  display_name        = "Example Spanner Instance"
  num_nodes           = 1
  processing_units    = 1
  labels = {
    environment = "example"
  }
}

# Create a Google Cloud Spanner database
resource "google_spanner_database" "example" {
  instance = google_spanner_instance.example.name
  name     = var.database_id
  ddl {
    database = var.database_id
  }
  labels = {
    environment = "example"
  }
}

# Create IAM bindings for Spanner database admin
resource "google_project_iam_binding" "spanner_database_admin" {
  project = var.project_id
  role    = "roles/spanner.databaseAdmin"
  members = [
    "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
  ]
}

# Create IAM bindings for Spanner database reader
resource "google_project_iam_binding" "spanner_database_reader" {
  project = var.project_id
  role    = "roles/spanner.databaseReader"
  members = [
    "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
  ]
}

# Create IAM bindings for Spanner instance admin
resource "google_project_iam_binding" "spanner_instance_admin" {
  project = var.project_id
  role    = "roles/spanner.instanceAdmin"
  members = [
    "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
  ]
}

# Create IAM bindings for Spanner instance reader
resource "google_project_iam_binding" "spanner_instance_reader" {
  project = var.project_id
  role    = "roles/spanner.instanceReader"
  members = [
    "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
  ]
}

# Output key resource attributes
output "spanner_instance_id" {
  value = google_spanner_instance.example.id
}

output "spanner_instance_name" {
  value = google_spanner_instance.example.name
}

output "spanner_database_id" {
  value = google_spanner_database.example.id
}

output "spanner_database_name" {
  value = google_spanner_database.example.name
}

output "project_id" {
  value = var.project_id
}

output "region" {
  value = var.region
}