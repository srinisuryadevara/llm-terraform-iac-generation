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

resource "google_storage_bucket_iam_binding" "storage" {
  bucket = google_storage_bucket.storage.name
  role   = "roles/storage.objectViewer"
  members = [
    "serviceAccount:${var.service_account}",
  ]
}