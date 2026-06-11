provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_spanner_instance" "example" {
  name                = var.instance_name
  config              = var.instance_config
  display_name        = var.instance_display_name
  num_nodes           = var.instance_num_nodes
  processing_units    = var.instance_processing_units
  labels              = var.instance_labels
  force_destroy       = var.instance_force_destroy
}

resource "google_spanner_database" "example" {
  instance = google_spanner_instance.example.name
  name     = var.database_name
  labels   = var.database_labels
}

resource "google_spanner_database_iam_policy" "example" {
  instance = google_spanner_instance.example.name
  database = google_spanner_database.example.name
  policy   = data.google_iam_policy.example.policy_data
}

data "google_iam_policy" "example" {
  binding {
    role = "roles/spanner.databaseUser"
    members = [
      "serviceAccount:${var.service_account_email}",
    ]
  }
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

variable "instance_processing_units" {
  type        = number
  description = "The number of processing units in the Spanner instance"
}

variable "instance_labels" {
  type        = map(string)
  description = "The labels of the Spanner instance"
}

variable "instance_force_destroy" {
  type        = bool
  description = "Whether to force destroy the Spanner instance"
}

variable "database_name" {
  type        = string
  description = "The name of the Spanner database"
}

variable "database_labels" {
  type        = map(string)
  description = "The labels of the Spanner database"
}

variable "service_account_email" {
  type        = string
  description = "The email of the service account"
}