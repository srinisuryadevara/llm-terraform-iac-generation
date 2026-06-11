# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Define input variables
variable "project_id" {
  type        = string
  description = "The ID of the project to create the resources in"
}

variable "region" {
  type        = string
  description = "The region to create the resources in"
}

variable "instance_id" {
  type        = string
  description = "The ID of the Spanner instance"
}

variable "database_id" {
  type        = string
  description = "The ID of the Spanner database"
}

variable "spanner_instance_config" {
  type        = string
  description = "The configuration of the Spanner instance"
}

variable "spanner_instance_nodes" {
  type        = number
  description = "The number of nodes in the Spanner instance"
}

# Create a Spanner instance
resource "google_spanner_instance" "example" {
  name                = var.instance_id
  config              = var.spanner_instance_config
  display_name        = "Example Spanner Instance"
  num_nodes           = var.spanner_instance_nodes
  force_destroy       = true
  labels = {
    environment = "example"
  }
}

# Create a Spanner database
resource "google_spanner_database" "example" {
  instance = google_spanner_instance.example.name
  name     = var.database_id
  ddl {
    database = var.database_id
    statements = [
      "CREATE TABLE Singers (SingerId INT64, FirstName STRING(1024), LastName STRING(1024), BirthDate DATE) PRIMARY KEY (SingerId)",
    ]
  }
  labels = {
    environment = "example"
  }
}

# Create IAM bindings for the Spanner database admin role
resource "google_project_iam_binding" "spanner_database_admin" {
  project = var.project_id
  role    = "roles/spanner.databaseAdmin"
  members = [
    "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
  ]
}

# Create IAM bindings for the Spanner database reader role
resource "google_project_iam_binding" "spanner_database_reader" {
  project = var.project_id
  role    = "roles/spanner.databaseReader"
  members = [
    "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
  ]
}

# Create IAM bindings for the Spanner instance admin role
resource "google_project_iam_binding" "spanner_instance_admin" {
  project = var.project_id
  role    = "roles/spanner.instanceAdmin"
  members = [
    "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
  ]
}

# Create IAM bindings for the Spanner instance reader role
resource "google_project_iam_binding" "spanner_instance_reader" {
  project = var.project_id
  role    = "roles/spanner.instanceReader"
  members = [
    "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
  ]
}

# Output key resource attributes
output "spanner_instance_id" {
  value       = google_spanner_instance.example.name
  description = "The ID of the Spanner instance"
}

output "spanner_database_id" {
  value       = google_spanner_database.example.name
  description = "The ID of the Spanner database"
}

output "spanner_instance_config" {
  value       = google_spanner_instance.example.config
  description = "The configuration of the Spanner instance"
}

output "spanner_instance_nodes" {
  value       = google_spanner_instance.example.num_nodes
  description = "The number of nodes in the Spanner instance"
}

output "project_id" {
  value       = var.project_id
  description = "The ID of the project"
}