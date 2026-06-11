provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "cloud_function_sa" {
  account_id = "cloud-function-sa"
}

resource "google_service_account_key" "cloud_function_sa_key" {
  service_account_id = google_service_account.cloud_function_sa.id
}

resource "google_cloudfunctions_function" "http_function" {
  name        = "http-function"
  runtime     = "nodejs16"
  service_account_email = google_service_account.cloud_function_sa.email
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.source_archive_bucket.name
  source_archive_object = google_storage_bucket_object.source_archive_object.name
  trigger_http {
    security_level = "SECURE_ALWAYS"
  }
  entry_point = "helloWorld"
}

resource "google_storage_bucket" "source_archive_bucket" {
  name     = "source-archive-bucket"
  location = var.region
}

resource "google_storage_bucket_object" "source_archive_object" {
  name   = "source-archive-object.zip"
  bucket = google_storage_bucket.source_archive_bucket.name
  source = "path/to/source/archive/object.zip"
}

resource "google_project_iam_binding" "cloud_functions_invoker" {
  project = var.project_id
  role    = "roles/cloudfunctions.invoker"
  members = [
    "serviceAccount:${google_service_account.cloud_function_sa.email}",
  ]
}

resource "google_project_iam_binding" "cloud_functions_service_agent" {
  project = var.project_id
  role    = "roles/cloudfunctions.serviceAgent"
  members = [
    "serviceAccount:service-${var.project_id}@gcf-admin-robot.iam.gserviceaccount.com",
  ]
}

resource "google_project_iam_binding" "storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  members = [
    "serviceAccount:${google_service_account.cloud_function_sa.email}",
  ]
}