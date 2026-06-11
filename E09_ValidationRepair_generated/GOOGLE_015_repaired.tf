provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "cloud_function" {
  account_id = var.service_account_id
  labels = {
    environment = "production"
    application = "cloud-functions"
  }
}

resource "google_service_account_key" "cloud_function" {
  service_account_id = google_service_account.cloud_function.id
  labels = {
    environment = "production"
    application = "cloud-functions"
  }
}

resource "google_cloudfunctions_function" "http_function" {
  name        = var.function_name
  runtime     = var.runtime
  region      = var.region
  service_account_email = google_service_account.cloud_function.email
  available_memory_mb   = var.memory
  timeout_seconds       = var.timeout
  entry_point           = var.entry_point
  labels = {
    environment = "production"
    application = "cloud-functions"
  }

  https_trigger {
    security_level = "SECURE_ALWAYS"
  }
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

variable "memory" {
  type = number
}

variable "timeout" {
  type = number
}

variable "entry_point" {
  type = string
}

output "cloud_function_id" {
  value = google_cloudfunctions_function.http_function.id
}

output "cloud_function_name" {
  value = google_cloudfunctions_function.http_function.name
}

output "cloud_function_trigger_url" {
  value = google_cloudfunctions_function.http_function.https_trigger_url
}

output "service_account_id" {
  value = google_service_account.cloud_function.id
}

output "service_account_email" {
  value = google_service_account.cloud_function.email
}