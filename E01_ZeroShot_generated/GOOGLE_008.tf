provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "uniform_bucket_level_access" {
  name                        = var.bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_policy" "deny_public_access" {
  bucket = google_storage_bucket.uniform_bucket_level_access.name
  policy = jsonencode({
    "version" = "1"
    "bindings" = [
      {
        "role" = "roles/storage.objectViewer"
        "members" = []
      },
      {
        "role" = "roles/storage.objectCreator"
        "members" = []
      },
      {
        "role" = "roles/storage.legacyObjectReader"
        "members" = []
      },
      {
        "role" = "roles/storage.legacyObjectOwner"
        "members" = []
      },
    ]
  })
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
}

variable "bucket_name" {
  type        = string
}