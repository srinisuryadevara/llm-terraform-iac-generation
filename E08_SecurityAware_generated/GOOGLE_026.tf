provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "service_account" {
  account_id = "cloud-functions-sa"
  description = "Service account for Cloud Functions"
  display_name = "Cloud Functions Service Account"
  tags = {
    environment = var.environment
  }
}

resource "google_service_account_key" "service_account_key" {
  service_account_id = google_service_account.service_account.id
}

resource "google_cloudfunctions_function" "function" {
  name        = "cloud-functions-example"
  description = "Example Cloud Functions function"
  runtime     = "nodejs14"
  available_memory_mb = 128
  source_archive_bucket = google_storage_bucket.source_archive.name
  source_archive_object = google_storage_bucket_object.source_archive_object.name
  trigger {
    http_method = "GET"
    url_path    = "/example"
  }
  service_account_email = google_service_account.service_account.email
  entry_point           = "example"
  tags = {
    environment = var.environment
  }
}

resource "google_storage_bucket" "source_archive" {
  name                        = "cloud-functions-source-archive"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
  encryption {
    default_kms_key_name = google_kms_key_ring.example.id
  }
  tags = {
    environment = var.environment
  }
}

resource "google_storage_bucket_object" "source_archive_object" {
  name   = "example.zip"
  bucket = google_storage_bucket.source_archive.name
  source = "example.zip"
}

resource "google_kms_key_ring" "example" {
  name     = "cloud-functions-key-ring"
  location = var.region
  tags = {
    environment = var.environment
  }
}

resource "google_kms_crypto_key" "example" {
  name     = "cloud-functions-crypto-key"
  key_ring = google_kms_key_ring.example.id
  purpose  = "ENCRYPTION"
  tags = {
    environment = var.environment
  }
}

resource "google_iam_policy" "cloud_functions_policy" {
  name        = "cloud-functions-policy"
  description = "Policy for Cloud Functions service account"
  policy_data = data.google_iam_policy.cloud_functions_policy.data
}

data "google_iam_policy" "cloud_functions_policy" {
  binding {
    role = "roles/cloudfunctions.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloudfunctions_function_iam_policy" "policy" {
  cloud_function = google_cloudfunctions_function.function.name
  policy_data    = google_iam_policy.cloud_functions_policy.policy_data
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "environment" {
  type        = string
  description = "Environment (e.g. dev, prod)"
}