terraform {
  required_version = ">= 0.12.8"
}

variable "project" {}
variable "region" {
  default = "us-central1"
}
variable "function_name" {}
variable "function_runtime" {
  default = "nodejs14"
}
variable "function_entry_point" {
  default = "helloWorld"
}
variable "function_source_archive_bucket" {}
variable "function_source_archive_object" {}
variable "service_account_email" {}

provider "google" {
  version = "~> 2.0"
  region  = var.region
  project = var.project
}

provider "google-beta" {
  version = "~> 2.9.0"
  region  = var.region
  project = var.project
}

resource "google_storage_bucket" "function_source_archive" {
  name     = var.function_source_archive_bucket
  location = var.region
}

resource "google_storage_bucket_object" "function_source_archive_object" {
  name   = var.function_source_archive_object
  bucket = google_storage_bucket.function_source_archive.name
  source = "function-source.zip"
}

resource "google_service_account" "function_service_account" {
  account_id = var.service_account_email
}

resource "google_cloudfunctions_function" "function" {
  name        = var.function_name
  runtime     = var.function_runtime
  entry_point = var.function_entry_point

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.function_source_archive.name
  source_archive_object = google_storage_bucket_object.function_source_archive_object.name

  trigger_http {
    security_level = "SECURE_ALWAYS"
  }

  service_account_email = google_service_account.function_service_account.email
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project
  region         = var.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}