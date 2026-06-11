provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "cloud_function_service_account" {
  account_id = var.service_account_id
  labels = {
    environment = "production"
    application = "cloud-functions"
  }
}

resource "google_service_account_key" "cloud_function_service_account_key" {
  service_account_id = google_service_account.cloud_function_service_account.id
  labels = {
    environment = "production"
    application = "cloud-functions"
  }
}

resource "google_cloudfunctions_function" "http_function" {
  name        = var.function_name
  runtime     = var.runtime
  region      = var.region
  labels = {
    environment = "production"
    application = "cloud-functions"
  }
  service_account_email = google_service_account.cloud_function_service_account.email
  available_memory_mb   = var.available_memory_mb
  timeout_seconds       = var.timeout_seconds
  entry_point          = var.entry_point
  source_archive_bucket = var.source_archive_bucket
  source_archive_object = var.source_archive_object
  trigger {
    http_method = var.http_method
    url_path    = var.url_path
  }
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

variable "source_archive_bucket" {
  type = string
}

variable "source_archive_object" {
  type = string
}

variable "http_method" {
  type = string
}

variable "url_path" {
  type = string
}

output "cloud_function_id" {
  value = google_cloudfunctions_function.http_function.id
}

output "cloud_function_url" {
  value = google_cloudfunctions_function.http_function.https_trigger_url
}

output "service_account_id" {
  value = google_service_account.cloud_function_service_account.id
!}

output "service_account_email" {
  value = google_service_account.cloud_function_service_account.email
}