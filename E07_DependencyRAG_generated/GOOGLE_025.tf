provider "google" {
  version = "~> 4.0"
  project = var.project
  region  = var.region
}

variable "project" {}
variable "region" {}
variable "function_name" {}
variable "function_runtime" {}
variable "function_entry_point" {}
variable "function_source_archive_bucket" {}
variable "function_source_archive_object" {}

resource "google_service_account" "cloud_function" {
  account_id = var.function_name
}

resource "google_cloudfunctions_function" "http_trigger" {
  name        = var.function_name
  runtime     = var.function_runtime
  entry_point = var.function_entry_point

  available_memory_mb   = 128
  source_archive_bucket = var.function_source_archive_bucket
  source_archive_object = var.function_source_archive_object

  trigger_http {
    security_level = "SECURE_ALWAYS"
  }

  service_account_email = google_service_account.cloud_function.email
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project
  region         = var.region
  cloud_function = google_cloudfunctions_function.http_trigger.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}