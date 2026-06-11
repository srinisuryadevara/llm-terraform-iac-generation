provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "bucket" {
  name     = var.bucket_name
  location = var.region
}

resource "google_service_account" "service_account" {
  account_id = var.service_account_id
}

resource "google_service_account_key" "service_account_key" {
  service_account_id = google_service_account.service_account.id
}

resource "google_cloudfunctions_function" "function" {
  name        = var.function_name
  runtime     = var.function_runtime
  region      = var.region
  entry_point = var.function_entry_point

  available_memory_mb   = var.function_available_memory_mb
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = var.function_source_archive_object

  trigger_http {
    security_level = "SECURE_OPTIONAL"
  }
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  cloud_function = google_cloudfunctions_function.function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "service_account_permissions" {
  project = var.project_id
  role    = "roles/cloudfunctions.serviceAgent"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "service_account_id" {
  type = string
}

variable "function_name" {
  type = string
}

variable "function_runtime" {
  type = string
}

variable "function_entry_point" {
  type = string
}

variable "function_available_memory_mb" {
  type = number
}

variable "function_source_archive_object" {
  type = string
}