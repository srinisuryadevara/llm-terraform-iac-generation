variable "project" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "us-central1"
}

variable "spanner_instance_name" {
  type        = string
}

variable "spanner_database_name" {
  type        = string
}

variable "spanner_instance_config" {
  type        = string
  default     = "regional-us-central1"
}

variable "spanner_num_nodes" {
  type        = number
  default     = 1
}

variable "spanner_iam_member" {
  type        = string
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_spanner_instance" "spanner_instance" {
  config        = var.spanner_instance_config
  display_name  = var.spanner_instance_name
  num_nodes     = var.spanner_num_nodes
  project       = var.project
  force_destroy = true
}

resource "google_spanner_database" "spanner_database" {
  instance            = google_spanner_instance.spanner_instance.name
  name                = var.spanner_database_name
  project             = var.project
  deletion_protection = false
}

resource "google_spanner_instance_iam_member" "spanner_instance_iam_member" {
  instance = google_spanner_instance.spanner_instance.name
  role     = "roles/spanner.databaseAdmin"
  member   = var.spanner_iam_member
}

resource "google_spanner_database_iam_member" "spanner_database_iam_member" {
  instance = google_spanner_instance.spanner_instance.name
  database = google_spanner_database.spanner_database.name
  role     = "roles/spanner.databaseReader"
  member   = var.spanner_iam_member
}