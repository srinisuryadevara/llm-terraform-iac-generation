provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "example" {
  provider = google
  location  = var.region
  repository_id = var.repository_id
  format       = "DOCKER"
}

resource "google_project_iam_binding" "example" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"

  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}