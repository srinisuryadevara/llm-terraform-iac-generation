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
variable "function_handler" {
  default = "index.handler"
}
variable "function_entry_point" {
  default = "index.js"
}
variable "service_account_email" {}

provider "google" {
  version = "~> 3.52.0"
  project = var.project
  region  = var.region
}

provider "google-beta" {
  version = "~> 3.52.0"
  project = var.project
  region  = var.region
}

resource "google_service_account" "function_service_account" {
  account_id = var.function_name
}

resource "google_service_account_key" "function_service_account_key" {
  service_account_id = google_service_account.function_service_account.id
}

resource "google_cloudfunctions_function" "function" {
  name        = var.function_name
  runtime     = var.function_runtime
  handler     = var.function_handler
  entry_point = var.function_entry_point

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_code.name
  trigger_http          = true

  service_account_email = var.service_account_email
}

resource "google_storage_bucket" "function_bucket" {
  name     = "${var.project}-${var.function_name}-bucket"
  location = var.region
}

resource "google_storage_bucket_object" "function_code" {
  name   = "${var.function_name}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = "${path.module}/${var.function_entry_point}"
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project
  region         = var.region
  cloud_function = google_cloudfunctions_function.function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}