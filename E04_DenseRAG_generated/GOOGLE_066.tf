# Configure the Google Cloud Provider
provider "google" {
  project = var.project
  region  = var.region
}

# Create a service account
resource "google_service_account" "example" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
}

# Create a service account key
resource "google_service_account_key" "example" {
  service_account_id = google_service_account.example.id
}

# Create an IAM binding for the service account
resource "google_project_iam_binding" "example" {
  project = var.project
  role    = var.role
  members = [
    "serviceAccount:${google_service_account.example.email}",
  ]
}

# Create an IAM policy for the service account
data "google_iam_policy" "example" {
  binding {
    role = var.role
    members = [
      "serviceAccount:${google_service_account.example.email}",
    ]
  }
}

# Output the service account email
output "service_account_email" {
  value = google_service_account.example.email
}

# Output the service account key
output "service_account_key" {
  value = base64decode(google_service_account_key.example.private_key)
  sensitive = true
}

variable "project" {
  type        = string
  description = "The ID of the project to create the service account in"
}

variable "region" {
  type        = string
  description = "The region to create the service account in"
}

variable "service_account_id" {
  type        = string
  description = "The ID of the service account to create"
}

variable "service_account_display_name" {
  type        = string
  description = "The display name of the service account to create"
}

variable "role" {
  type        = string
  description = "The role to assign to the service account"
}