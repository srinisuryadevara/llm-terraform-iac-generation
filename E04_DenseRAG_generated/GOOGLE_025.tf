terraform {
  required_version = ">= 0.12.8"
}

variable "project" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "function_name" {
  type = string
}

variable "function_runtime" {
  type    = string
  default = "nodejs14"
}

variable "function_handler" {
  type = string
}

variable "service_account_email" {
  type = string
}

provider "google" {
  project = var.project
  region  = var.region
}

provider "google-beta" {
  project = var.project
  region  = var.region
}

resource "google_service_account" "function_service_account" {
  account_id = "function-service-account"
}

resource "google_cloudfunctions_function" "function" {
  name        = var.function_name
  runtime     = var.function_runtime
  handler     = var.function_handler
  service_account_email = google_service_account.function_service_account.email
  available_memory_mb   = 128
  timeout_seconds       = 60
  entry_point           = "main"
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project
  region         = var.region
  cloud_function = google_cloudfunctions_function.function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

resource "google_cloudfunctions_function" "http_function" {
  name        = "${var.function_name}-http"
  runtime     = var.function_runtime
  handler     = var.function_handler
  service_account_email = google_service_account.function_service_account.email
  available_memory_mb   = 128
  timeout_seconds       = 60
  entry_point           = "main"
  trigger_http {
    security_level = "SECURE_ALWAYS"
  }
}