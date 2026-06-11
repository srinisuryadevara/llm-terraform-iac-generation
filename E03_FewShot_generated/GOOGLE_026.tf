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
  service_account_email = google_service_account.cloud_function.email
  source_archive_bucket = var.source_archive_bucket
  source_archive_object = var.source_archive_object
  trigger_http {
    security_level = "SECURE_ALWAYS"
  }
  entry_point = var.entry_point
  environment_variables = {
    VARIABLE = var.environment_variable
  }
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  cloud_function = google_cloudfunctions_function.http_function.name
  role          = "roles/cloudfunctions.invoker"
  member        = "allUsers"
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

variable "source_archive_bucket" {
  type = string
}

variable "source_archive_object" {
  type = string
}

variable "entry_point" {
  type = string
}

variable "environment_variable" {
  type = string
}