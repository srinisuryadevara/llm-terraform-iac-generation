provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "private_bucket" {
  name                        = var.bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_policy" "private_bucket_policy" {
  bucket = google_storage_bucket.private_bucket.name
  policy = data.google_iam_policy.private_bucket_policy.policy
}

data "google_iam_policy" "private_bucket_policy" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${var.service_account_email}",
    ]
  }
}

resource "google_storage_bucket_public_access_block" "private_bucket_block" {
  bucket = google_storage_bucket.private_bucket.name

  block_all               = true
  ignore_acle             = true
  restrict_default_scopes = true
}