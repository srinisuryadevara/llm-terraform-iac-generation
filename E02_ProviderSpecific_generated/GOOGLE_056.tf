provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "cloud_function_sa" {
  account_id = "cloud-function-sa"
}

resource "google_cloud_functions_function" "http_function" {
  name        = "http-function"
  runtime     = "nodejs16"
  entry_point = "helloWorld"
  service_account_email = google_service_account.cloud_function_sa.email
  available_memory_mb   = 128
  trigger_http {
    security_level = "SECURE_ALWAYS"
  }
}

resource "google_cloud_functions_function_iam_member" "invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloud_functions_function.http_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}