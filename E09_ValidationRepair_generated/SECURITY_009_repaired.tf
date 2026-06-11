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

resource "google_storage_bucket" "private_bucket" {
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
    environment = "private"
    project     = var.project_id
  }
}

resource "google_storage_bucket_iam_policy" "private_bucket_policy" {
  bucket = google_storage_bucket.private_bucket.name
  policy = data.google_iam_policy.private_bucket_policy.policy_data
}

data "google_iam_policy" "private_bucket_policy" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:storage-${var.project_id}@gs-project-accounts.iam.gserviceaccount.com",
    ]
  }
}

output "bucket_id" {
  value       = google_storage_bucket.private_bucket.id
  description = "The ID of the private bucket"
}

output "bucket_name" {
  value       = google_storage_bucket.private_bucket.name
  description = "The name of the private bucket"
}

output "bucket_self_link" {
  value       = google_storage_bucket.private_bucket.self_link
  description = "The self link of the private bucket"
}