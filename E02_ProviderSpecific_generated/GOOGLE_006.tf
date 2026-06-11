provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "example" {
  account_id = "example-sa"
}

resource "google_project_iam_binding" "project" {
  project = var.project_id
  role    = "roles/viewer"

  members = [
    "serviceAccount:${google_service_account.example.email}",
  ]
}

resource "google_project_iam_binding" "logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"

  members = [
    "serviceAccount:${google_service_account.example.email}",
  ]
}

resource "google_project_iam_binding" "monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${google_service_account.example.email}",
  ]
}