variable "project" {
  type        = string
  description = "The ID of the project"
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket"
}

variable "location" {
  type        = string
  description = "The location of the bucket"
}

variable "lifecycle_rule_age" {
  type        = number
  description = "The age in days for the lifecycle rule"
}

provider "google" {
  project = var.project
  region  = "us-central1"
}

resource "google_storage_bucket" "private_bucket" {
  name          = var.bucket_name
  location      = var.location
  force_destroy = true
  versioning {
    enabled = false
  }
  lifecycle {
    prevent_destroy = false
  }
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_binding" "private_bucket_binding" {
  bucket = google_storage_bucket.private_bucket.name
  role   = "roles/storage.objectViewer"
  members = [
    "projectOwner:${var.project}",
    "projectEditor:${var.project}",
  ]
}

resource "google_storage_bucket_lifecycle_rule" "lifecycle_rule" {
  bucket = google_storage_bucket.private_bucket.name
  rule {
    action {
      type = "Delete"
    }
    condition {
      age = var.lifecycle_rule_age
    }
  }
}