terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.bucket_name
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "bucket_name" {
  type = string
}

variable "location" {
  type    = string
  default = "US"
}

resource "google_storage_bucket" "uniform_bucket_access" {
  name               = var.bucket_name
  location           = var.location
  bucket_policy_only = true
  uniform_bucket_level_access = {
    enabled = true
  }
}

resource "google_storage_bucket_iam_policy" "no_public_access" {
  bucket      = google_storage_bucket.uniform_bucket_access.name
  policy_data = data.google_iam_policy.no_public_access.policy_data
}

data "google_iam_policy" "no_public_access" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${var.project_id}@appspot.gserviceaccount.com",
    ]
  }
}