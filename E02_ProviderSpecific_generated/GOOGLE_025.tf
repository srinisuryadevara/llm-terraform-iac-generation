provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "cloud_function_sa" {
  account_id = "cloud-function-sa"
}

resource "google_cloud_functions_service_account_iam_member" "cloud_function_sa_iam" {
  service_account_id = google_service_account.cloud_function_sa.id
  role               = "roles/cloudfunctions.invoker"
  member             = "allUsers"
}

resource "google_cloud_functions_function" "http_function" {
  name        = "http-function"
  runtime     = "nodejs16"
  service_account_email = google_service_account.cloud_function_sa.email
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_code.name
  trigger_http {
    security_level = "SECURE_ALWAYS"
  }
  entry_point = "helloWorld"
}

resource "google_storage_bucket" "function_bucket" {
  name     = "function-bucket"
  location = var.region
}

resource "google_storage_bucket_object" "function_code" {
  name   = "function-code.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = "./function-code.zip"
}