provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "private_bucket" {
  name                        = var.bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
  versioning {
    enabled = false
  }
  labels = {
    environment = "production"
    owner       = "cloud-team"
  }
}

resource "google_storage_bucket_iam_policy" "private_bucket_policy" {
  bucket = google_storage_bucket.private_bucket.name
  policy_data = jsonencode({
    "version" = "1",
    "bindings" = [
      {
        "role" = "roles/storage.objectViewer",
        "members" = [
          "serviceAccount:${var.service_account_email}",
        ]
      },
    ]
  })
}

resource "google_storage_bucket_public_access_block" "private_bucket_block" {
  bucket = google_storage_bucket.private_bucket.name
  block_all = true
  labels = {
    environment = "production"
    owner       = "cloud-team"
  }
}

output "private_bucket_name" {
  value       = google_storage_bucket.private_bucket.name
  description = "The name of the private bucket"
}

output "private_bucket_id" {
  value       = google_storage_bucket.private_bucket.id
  description = "The ID of the private bucket"
}

output "private_bucket_iam_policy" {
  value       = google_storage_bucket_iam_policy.private_bucket_policy.policy_data
  description = "The IAM policy of the private bucket"
  sensitive   = true
}