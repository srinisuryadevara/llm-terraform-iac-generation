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

variable "service_account_id" {
  type        = string
  sensitive   = true
}

resource "google_service_account" "example" {
  account_id = var.service_account_id
}

resource "google_project_iam_binding" "example" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  members = [
    "serviceAccount:${google_service_account.example.email}",
  ]
}

resource "google_project_iam_binding" "example2" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  members = [
    "serviceAccount:${google_service_account.example.email}",
  ]
}

resource "google_project_iam_binding" "example3" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  members = [
    "serviceAccount:${google_service_account.example.email}",
  ]
}

output "service_account_email" {
  value       = google_service_account.example.email
  description = "The email of the service account"
}