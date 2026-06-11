variable "project" {
  type        = string
  description = "The ID of the project to create the bucket in"
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket to create"
}

variable "location" {
  type        = string
  description = "The location of the bucket to create"
}

variable "lifecycle_rule_age" {
  type        = number
  description = "The age in days after which to delete objects"
}

provider "google" {
  project = var.project
  region  = "us-central1"
}

resource "google_storage_bucket" "private_bucket" {
  name     = var.bucket_name
  location = var.location
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_binding" "private_bucket_binding" {
  bucket = google_storage_bucket.private_bucket.name
  role   = "roles/storage.objectViewer"
  members = [
    "projectEditor:$(google_storage_bucket.private_bucket.project)",
    "projectViewer:$(google_storage_bucket.private_bucket.project)"
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