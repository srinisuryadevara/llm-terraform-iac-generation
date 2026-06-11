provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "example" {
  provider = google

  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"

  labels = {
    environment = var.environment
    team        = var.team
  }
}

resource "google_project_iam_binding" "example" {
  provider = google

  project = var.project_id
  role    = "roles/artifactregistry.reader"

  members = [
    "serviceAccount:${var.service_account_email}",
  ]

  condition {
    title       = "artifact-registry-access-condition"
    description = "Only allow access to the artifact registry repository"
    expression  = "resource.name.startsWith('projects/${var.project_id}/repositories/${var.repository_id}')"
  }
}

resource "google_kms_key_ring" "example" {
  provider = google

  name     = var.kms_key_ring_name
  location = var.region
}

resource "google_kms_crypto_key" "example" {
  provider = google

  name            = var.kms_crypto_key_name
  key_ring        = google_kms_key_ring.example.id
  rotation_period = "604800s"
}

resource "google_kms_key_ring_iam_binding" "example" {
  provider = google

  key_ring_id = google_kms_key_ring.example.id
  role        = "roles/owner"

  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}

resource "google_storage_bucket" "example" {
  provider = google

  name                        = var.storage_bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = google_kms_crypto_key.example.id
  }

  versioning {
    enabled = true
  }

  labels = {
    environment = var.environment
    team        = var.team
  }
}

resource "google_storage_bucket_iam_binding" "example" {
  provider = google

  bucket = google_storage_bucket.example.name
  role   = "roles/storage.objectViewer"

  members = [
    "serviceAccount:${var.service_account_email}",
  ]
}