provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "cloud_function_sa" {
  account_id = var.service_account_id
}

resource "google_service_account_key" "cloud_function_sa_key" {
  service_account_id = google_service_account.cloud_function_sa.id
}

resource "google_cloudfunctions_function" "http_function" {
  name        = var.function_name
  runtime     = var.runtime
  region      = var.region
  service_account_email = google_service_account.cloud_function_sa.email
  source_archive_bucket = var.source_archive_bucket
  source_archive_object = var.source_archive_object
  trigger_http {
    security_level = "SECURE_OPTIONAL"
  }
  entry_point = var.entry_point
  environment_variables = var.environment_variables
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.http_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}