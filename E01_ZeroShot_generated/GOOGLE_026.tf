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
  available_memory_mb   = var.available_memory_mb
  timeout_seconds      = var.timeout_seconds
  entry_point          = var.entry_point
  trigger_http {
    security_level = "SECURE_OPTIONAL"
  }
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
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

variable "available_memory_mb" {
  type = number
}

variable "timeout_seconds" {
  type = number
}

variable "entry_point" {
  type = string
}