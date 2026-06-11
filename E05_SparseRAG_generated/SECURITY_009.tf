locals {
  project         = var.project
  location        = var.location
  bucket_name     = "${var.project}_${var.location}_storage"
}

variable "project" {
  type        = string
  description = "The ID of the project"
}

variable "location" {
  type        = string
  description = "The location of the bucket"
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

resource "google_storage_bucket_iam_policy" "storage" {
  bucket      = google_storage_bucket.storage.name
  policy_data = data.google_iam_policy.storage.policy_data
}

data "google_iam_policy" "storage" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${var.service_account}",
    ]
  }
}

resource "google_storage_bucket_lifecycle_rule" "storage" {
  bucket     = google_storage_bucket.storage.name
  rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }
}