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

  available_memory_mb   = var.available_memory_mb
  source_archive_bucket = var.source_archive_bucket
  source_archive_object = var.source_archive_object

  https_trigger {
    security_level = "SECURE_ALWAYS"
  }

  service_account_email = google_service_account.cloud_function.email
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.http_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "service_account_id" {
  type = string
}

variable "function_name" {
  type = string
}

variable "runtime" {
  type = string
}

variable "entry_point" {
  type = string
}

variable "available_memory_mb" {
  type = number
}

variable "source_archive_bucket" {
  type = string
}

variable "source_archive_object" {
  type = string
}