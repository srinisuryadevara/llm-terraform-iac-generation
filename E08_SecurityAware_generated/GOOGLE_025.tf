provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "cloud_function_sa" {
  account_id = "cloud-function-sa"
  description = "Service account for Cloud Function"
  tags = {
    environment = var.environment
  }
}

resource "google_service_account_key" "cloud_function_sa_key" {
  service_account_id = google_service_account.cloud_function_sa.id
}

resource "google_cloudfunctions_function" "http_function" {
  name        = "http-function"
  runtime     = "nodejs16"
  region      = var.region
  entry_point = "httpFunction"
  service_account_email = google_service_account.cloud_function_sa.email
  tags = {
    environment = var.environment
  }
  https_trigger {
    security_level = "SECURE_ALWAYS"
    min_tls_version = "TLS_1_2"
  }
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.http_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "us-central1"
}

variable "environment" {
  type        = string
  default     = "dev"
}