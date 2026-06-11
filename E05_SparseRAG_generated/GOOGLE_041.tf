# VARIABLES
variable "project" {}
variable "region" {
  default = "us-central1"
}
variable "instance_name" {}
variable "database_name" {}
variable "spanner_admin_email" {}
variable "spanner_database_admin_email" {}

# PROVIDERS
provider "google" {
  version = "~>4.0"
  project = var.project
  region  = var.region
}

# SPANNER INSTANCE
resource "google_spanner_instance" "spanner_instance" {
  config        = "regional-${var.region}"
  display_name  = var.instance_name
  num_nodes     = 1
  force_destroy = true
}

# SPANNER INSTANCE IAM BINDING
resource "google_spanner_instance_iam_binding" "spanner_instance_iam_binding" {
  instance = google_spanner_instance.spanner_instance.name
  role     = "roles/spanner.databaseAdmin"
  members = [
    "user:${var.spanner_admin_email}",
  ]
}

# SPANNER DATABASE
resource "google_spanner_database" "spanner_database" {
  instance            = google_spanner_instance.spanner_instance.name
  name                = var.database_name
  deletion_protection = false
}

# SPANNER DATABASE IAM BINDING
resource "google_spanner_database_iam_binding" "spanner_database_iam_binding" {
  instance = google_spanner_instance.spanner_instance.name
  database = google_spanner_database.spanner_database.name
  role     = "roles/spanner.databaseReader"
  members = [
    "user:${var.spanner_database_admin_email}",
  ]
}