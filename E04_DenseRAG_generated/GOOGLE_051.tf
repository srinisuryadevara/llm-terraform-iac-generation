terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.bucket_name
  }
}

variable "bucket_name" {
  type        = string
  description = "Name of the Cloud Storage bucket"
}

variable "location" {
  type        = string
  default     = "US"
  description = "Location of the Cloud Storage bucket"
}

variable "project" {
  type        = string
  description = "ID of the project where the bucket will be created"
}

provider "google" {
  project = var.project
  region  = "us-central1"
}

resource "google_storage_bucket" "uniform_bucket_access" {
  name     = var.bucket_name
  location = var.location
  uniform_bucket_level_access = true
  force_destroy = true
}

resource "google_storage_bucket_iam_policy" "private_policy" {
  bucket = google_storage_bucket.uniform_bucket_access.name
  policy_data = jsonencode({
    "version" = 1
    "bindings" = [
      {
        "role" = "roles/storage.objectViewer"
        "members" = [
          "projectEditor:$(google_storage_bucket.uniform_bucket_access.project)",
          "projectViewer:$(google_storage_bucket.uniform_bucket_access.project)"
        ]
      },
      {
        "role" = "roles/storage.objectCreator"
        "members" = [
          "projectEditor:$(google_storage_bucket.uniform_bucket_access.project)",
          "projectOwner:$(google_storage_bucket.uniform_bucket_access.project)"
        ]
      }
    ]
  })
}

resource "google_storage_bucket_iam_binding" "deny_public_access" {
  bucket = google_storage_bucket.uniform_bucket_access.name
  role   = "roles/storage.objectViewer"
  members = []
}