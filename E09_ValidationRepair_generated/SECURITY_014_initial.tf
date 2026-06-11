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