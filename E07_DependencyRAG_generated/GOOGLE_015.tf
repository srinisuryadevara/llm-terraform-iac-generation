provider "google" {
  version = "~> 3.52.0"
  project = var.project
  region  = var.region
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "function_name" {
  type = string
}

variable "function_runtime" {
  type = string
}

variable "function_handler" {
  type = string
}

variable "function_entry_point" {
  type = string
}

variable "service_account_email" {
  type = string
}

resource "google_service_account" "cloud_functions_service_account" {
  account_id = var.service_account_email
}

resource "google_cloudfunctions_function" "cloud_functions_function" {
  name        = var.function_name
  runtime     = var.function_runtime
  handler     = var.function_handler
  entry_point = var.function_entry_point

  service_account_email = google_service_account.cloud_functions_service_account.email

  trigger_http {
    security_level = "SECURE_ALWAYS"
  }
}

resource "google_cloudfunctions_function_iam_member" "cloud_functions_invoker" {
  project        = var.project
  region         = var.region
  cloud_function = google_cloudfunctions_function.cloud_functions_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}