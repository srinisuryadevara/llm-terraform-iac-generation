provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "example" {
  account_id = var.service_account_id
}

resource "google_service_account_key" "example" {
  service_account_id = google_service_account.example.id
}

resource "google_project_iam_binding" "example" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  members = [
    "serviceAccount:${google_service_account.example.email}",
  ]
}

resource "google_project_iam_binding" "example_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  members = [
    "serviceAccount:${google_service_account.example.email}",
  ]
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