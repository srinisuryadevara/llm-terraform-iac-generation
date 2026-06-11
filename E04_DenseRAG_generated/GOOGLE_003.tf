terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.bucket_name
  }
}

variable "bucket_name" {
  type        = string
  description = "The name of the Cloud Storage bucket"
}

variable "location" {
  type        = string
  default     = "US"
  description = "The location of the Cloud Storage bucket"
}

provider "google" {
  version = "~> 4.0"
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the Google Cloud project"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The region of the Google Cloud project"
}

resource "google_storage_bucket" "uniform_bucket_access" {
  name     = var.bucket_name
  location = var.location
  force_destroy = true

  uniform_bucket_level_access {
    enabled = true
  }
}

resource "google_storage_bucket_iam_policy" "private_policy" {
  bucket      = google_storage_bucket.uniform_bucket_access.name
  policy_data = data.google_iam_policy.private_policy.policy_data
}

data "google_iam_policy" "private_policy" {
  binding {
    role = "roles/storage.objectViewer"
    members = []
  }
  binding {
    role = "roles/storage.objectCreator"
    members = []
  }
  binding {
    role = "roles/storage.legacyObjectReader"
    members = []
  }
  binding {
    role = "roles/storage.legacyBucketReader"
    members = []
  }
}