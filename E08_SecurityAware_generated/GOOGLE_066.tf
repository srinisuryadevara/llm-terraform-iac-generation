variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "service_account_email" {
  type        = string
  description = "Service account email"
}

variable "environment" {
  type        = string
  description = "Environment (e.g., dev, prod)"
}

variable "owner" {
  type        = string
  description = "Owner of the resources"
}

resource "google_project_iam_binding" "service_account" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
  depends_on = [
    google_service_account.service_account,
  ]
}

resource "google_service_account" "service_account" {
  account_id = "minimal-service-account"
  project    = var.project
}

resource "google_project_iam_binding" "logging" {
  project = var.project
  role    = "roles/logging.logWriter"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
  depends_on = [
    google_service_account.service_account,
  ]
}

resource "google_project_iam_binding" "monitoring" {
  project = var.project
  role    = "roles/monitoring.metricWriter"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
  depends_on = [
    google_service_account.service_account,
  ]
}

resource "google_project_iam_binding" "storage" {
  project = var.project
  role    = "roles/storage.objectCreator"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
  depends_on = [
    google_service_account.service_account,
  ]
}

output "service_account_email" {
  value       = google_service_account.service_account.email
  description = "Service account email"
}

output "project" {
  value       = var.project
  description = "GCP project ID"
}

output "region" {
  value       = var.region
  description = "GCP region"
}

output "environment" {
  value       = var.environment
  description = "Environment (e.g., dev, prod)"
}

output "owner" {
  value       = var.owner
  description = "Owner of the resources"
}