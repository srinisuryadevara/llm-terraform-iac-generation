variable "project_id" {
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  type        = string
  sensitive   = true
}

variable "location" {
  type        = string
  sensitive   = true
}

variable "storage_class" {
  type        = string
  sensitive   = true
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
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = "production"
    managed_by  = "terraform"
  }
}

resource "google_storage_bucket_iam_policy" "policy" {
  bucket = google_storage_bucket.bucket.name
  policy_data = jsonencode({
    "version" : 1,
    "bindings" : [
      {
        "role" : "roles/storage.admin",
        "members" : [
          "serviceAccount:storage-admin@${var.project_id}.iam.gserviceaccount.com"
        ]
      },
      {
        "role" : "roles/storage.objectViewer",
        "members" : [
          "serviceAccount:object-viewer@${var.project_id}.iam.gserviceaccount.com"
        ]
      }
    ]
  })
}

output "bucket_id" {
  value       = google_storage_bucket.bucket.id
  description = "The ID of the Cloud Storage bucket"
}

output "bucket_name" {
  value       = google_storage_bucket.bucket.name
  description = "The name of the Cloud Storage bucket"
}

output "bucket_self_link" {
  value       = google_storage_bucket.bucket.self_link
  description = "The self link of the Cloud Storage bucket"
}

output "bucket_url" {
  value       = google_storage_bucket.bucket.url
  description = "The URL of the Cloud Storage bucket"
}