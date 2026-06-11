variable "project_id" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "location" {
  type = string
}

variable "storage_class" {
  type = string
}

variable "lifecycle_rule_enabled" {
  type = bool
}

variable "lifecycle_rule_age" {
  type = number
}

provider "google" {
  project = var.project_id
  region  = var.location
}

resource "google_storage_bucket" "bucket" {
  name                        = var.bucket_name
  location                    = var.location
  storage_class               = var.storage_class
  uniform_bucket_level_access = true
  force_destroy               = true

  lifecycle_rule {
    enabled = var.lifecycle_rule_enabled
    action {
      type = "Delete"
    }
    condition {
      age = var.lifecycle_rule_age
    }
  }
}

resource "google_storage_bucket_iam_policy" "bucket_policy" {
  bucket = google_storage_bucket.bucket.name
  policy = jsonencode({
    "version" = "1"
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