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

resource "google_service_account" "cloud_function" {
  account_id = var.function_name
}

resource "google_cloudfunctions_function" "http_function" {
  name        = var.function_name
  runtime     = var.function_runtime
  region      = var.region
  service_account_email = google_service_account.cloud_function.email

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_code.name
  trigger {
    http_method = "GET"
    url_path    = "/"
  }
}

resource "google_storage_bucket" "function_bucket" {
  name     = "${var.function_name}-bucket"
  location = var.region
}

resource "google_storage_bucket_object" "function_code" {
  name   = "${var.function_name}-code.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = file("${path.module}/function_code.zip")
}

resource "google_project_iam_member" "cloud_function_invoker" {
  project = var.project
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${google_service_account.cloud_function.email}"
}

resource "google_project_iam_member" "cloud_function_service_account_user" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${var.service_account_email}"
}