provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  type        = string
  sensitive   = true
}

resource "google_storage_bucket" "private_bucket" {
  name                        = var.bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_policy" "private_bucket_policy" {
  bucket      = google_storage_bucket.private_bucket.name
  policy_data = jsonencode({
    "version" = "1"
    "bindings" = [
      {
        "role" = "roles/storage.admin"
        "members" = [
          "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
        ]
      },
    ]
  })
}

resource "google_storage_bucket_lifecycle_rule" "private_bucket_lifecycle" {
  bucket     = google_storage_bucket.private_bucket.name
  rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }
}