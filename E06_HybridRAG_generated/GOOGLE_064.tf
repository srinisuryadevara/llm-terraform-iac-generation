# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Create a Spanner instance
resource "google_spanner_instance" "spanner_instance" {
  config        = var.instance_config
  display_name  = var.instance_name
  num_nodes     = var.instance_nodes
  project       = var.project_id
  force_destroy = var.force_destroy
}

# Create a Spanner database
resource "google_spanner_database" "spanner_database" {
  instance            = google_spanner_instance.spanner_instance.name
  name                = var.database_name
  project             = var.project_id
  deletion_protection = var.deletion_protection
}

# Create IAM bindings for the Spanner instance
resource "google_spanner_instance_iam_binding" "spanner_instance_iam_binding" {
  instance = google_spanner_instance.spanner_instance.name
  role     = var.instance_iam_role
  members = var.instance_iam_members
}

# Create IAM bindings for the Spanner database
resource "google_spanner_database_iam_binding" "spanner_database_iam_binding" {
  instance = google_spanner_instance.spanner_instance.name
  database = google_spanner_database.spanner_database.name
  role     = var.database_iam_role
  members = var.database_iam_members
}

# Create IAM members for the Spanner instance
resource "google_spanner_instance_iam_member" "spanner_instance_iam_member" {
  instance = google_spanner_instance.spanner_instance.name
  role     = var.instance_iam_role
  member   = var.instance_iam_member
}

# Create IAM members for the Spanner database
resource "google_spanner_database_iam_member" "spanner_database_iam_member" {
  instance = google_spanner_instance.spanner_instance.name
  database = google_spanner_database.spanner_database.name
  role     = var.database_iam_role
  member   = var.database_iam_member
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region of the project"
}

variable "instance_config" {
  type        = string
  description = "The configuration of the Spanner instance"
}

variable "instance_name" {
  type        = string
  description = "The name of the Spanner instance"
}

variable "instance_nodes" {
  type        = number
  description = "The number of nodes in the Spanner instance"
}

variable "force_destroy" {
  type        = bool
  description = "Whether to force destroy the Spanner instance"
}

variable "database_name" {
  type        = string
  description = "The name of the Spanner database"
}

variable "deletion_protection" {
  type        = bool
  description = "Whether to enable deletion protection for the Spanner database"
}

variable "instance_iam_role" {
  type        = string
  description = "The IAM role for the Spanner instance"
}

variable "instance_iam_members" {
  type        = list(string)
  description = "The IAM members for the Spanner instance"
}

variable "database_iam_role" {
  type        = string
  description = "The IAM role for the Spanner database"
}

variable "database_iam_members" {
  type        = list(string)
  description = "The IAM members for the Spanner database"
}

variable "instance_iam_member" {
  type        = string
  description = "The IAM member for the Spanner instance"
}

variable "database_iam_member" {
  type        = string
  description = "The IAM member for the Spanner database"
}