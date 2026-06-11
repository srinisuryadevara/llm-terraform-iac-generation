provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "secure_bucket" {
  name                        = var.bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = google_kms_crypto_key.secure_key.id
  }

  versioning {
    enabled = true
  }

  labels = {
    environment = var.environment
    project     = var.project_id
  }
}

resource "google_kms_key_ring" "secure_key_ring" {
  name     = var.kms_key_ring_name
  location = var.region
}

resource "google_kms_crypto_key" "secure_key" {
  name            = var.kms_crypto_key_name
  key_ring        = google_kms_key_ring.secure_key_ring.id
  rotation_period = "604800s"
}

resource "google_kms_crypto_key_version" "secure_key_version" {
  crypto_key = google_kms_crypto_key.secure_key.id
}

resource "google_iam_policy" "secure_bucket_policy" {
  binding {
    role = "roles/storage.objectViewer"

    members = [
      "serviceAccount:${var.service_account_email}",
    ]
  }
}

resource "google_storage_bucket_iam_policy" "secure_bucket_iam_policy" {
  bucket      = google_storage_bucket.secure_bucket.name
  policy_data = google_iam_policy.secure_bucket_policy.policy_data
}