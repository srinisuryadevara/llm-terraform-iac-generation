provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "cloud_function" {
  account_id = var.service_account_id
}

resource "google_service_account_key" "cloud_function" {
  service_account_id = google_service_account.cloud_function.id
}

resource "google_cloudfunctions_function" "http_function" {
  name        = var.function_name
  runtime     = var.runtime
  region      = var.region
  entry_point = var.entry_point

  available_memory_mb   = var.memory
  source_archive_bucket = var.bucket_name
  source_archive_object = var.archive_name

  trigger_http {
    security_level = "SECURE_ALWAYS"
  }

  service_account_email = google_service_account.cloud_function.email
}

resource "google_project_iam_member" "cloud_function_invoker" {
  project = var.project_id
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${google_service_account.cloud_function.email}"
}

resource "google_storage_bucket" "cloud_function_bucket" {
  name     = var.bucket_name
  location = var.region
}

resource "google_storage_bucket_object" "cloud_function_archive" {
  name   = var.archive_name
  bucket = google_storage_bucket.cloud_function_bucket.name
  source = var.source_code_path
}