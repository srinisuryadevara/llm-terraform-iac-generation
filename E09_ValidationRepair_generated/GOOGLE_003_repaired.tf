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
    enabled = true
  }
  labels = {
    environment = "production"
    created_by  = "terraform"
  }
}

resource "google_storage_bucket_iam_policy" "private_bucket_policy" {
  bucket = google_storage_bucket.private_bucket.name
  policy_data = jsonencode({
    "bindings": [
      {
        "role": "roles/storage.admin",
        "members": [
          "serviceAccount:${var.service_account_email}",
        ]
      },
      {
        "role": "roles/storage.objectViewer",
        "members": [
          "serviceAccount:${var.service_account_email}",
        ]
      },
    ],
    "etag": "BwWKmjyGDUk="
  })
}

resource "google_storage_bucket_public_access_prevention" "private_bucket_prevention" {
  bucket = google_storage_bucket.private_bucket.name
  prevention_type = "enforced"
}

output "private_bucket_id" {
  value = google_storage_bucket.private_bucket.id
}

output "private_bucket_name" {
  value = google_storage_bucket.private_bucket.name
}

output "private_bucket_self_link" {
  value = google_storage_bucket.private_bucket.self_link
}