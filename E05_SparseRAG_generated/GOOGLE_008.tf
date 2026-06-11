locals {
  project         = var.project
  location        = var.location
  bucket_name     = "${local.project}_${local.location}_storage"
}

terraform {
  backend "gcs" {
    prefix = "GCP_Storage/state"
    bucket = var.backend_bucket
  }
}

provider "google" {
  project = local.project
  region  = var.region
}

resource "google_storage_bucket" "storage" {
  name               = local.bucket_name
  location           = local.location
  bucket_policy_only = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_policy" "no_public_access" {
  bucket      = google_storage_bucket.storage.name
  policy_data = data.google_iam_policy.no_public_access.policy_data
}

data "google_iam_policy" "no_public_access" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${google_service_account.storage.email}",
    ]
  }
}

resource "google_service_account" "storage" {
  account_id   = "storage-account"
  display_name = "Storage Service Account"
}