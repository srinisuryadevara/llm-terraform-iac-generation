terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.bucket_name
  }
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket"
}

variable "location" {
  type        = string
  default     = "US"
  description = "The location of the bucket"
}

provider "google" {
  version = "~> 4.0"
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The region of the project"
}

resource "google_storage_bucket" "uniform_bucket_access" {
  name     = var.bucket_name
  location = var.location
  uniform_bucket_level_access = true
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_policy" "private_policy" {
  bucket = google_storage_bucket.uniform_bucket_access.name
  policy_data = jsonencode({
    "version" = 1
    "bindings" = [
      {
        "role" = "roles/storage.objectViewer"
        "members" = [
          "serviceAccount:${var.project_id}@appspot.gserviceaccount.com",
        ]
      },
    ]
  })
}