terraform {
  required_version = ">= 0.12.8"
}

# ---------------------------------------------------------------------------------------------------------------------
# VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------------------------------------------------
# PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------------------------------------------------
# SERVICE ACCOUNT
# ---------------------------------------------------------------------------------------------------------------------

resource "google_service_account" "cloud_function" {
  account_id = var.function_name
}

resource "google_service_account_key" "cloud_function" {
  service_account_id = google_service_account.cloud_function.id
}

# ---------------------------------------------------------------------------------------------------------------------
# CLOUD FUNCTION
# ---------------------------------------------------------------------------------------------------------------------

resource "google_cloudfunctions_function" "http_function" {
  name        = var.function_name
  runtime     = var.function_runtime
  handler     = var.function_handler
  entry_point = var.function_entry_point

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.cloud_function.name
  source_archive_object = google_storage_bucket_object.cloud_function.name
  trigger_http          = true

  service_account_email = google_service_account.cloud_function.email
}

resource "google_storage_bucket" "cloud_function" {
  name     = "${var.function_name}-bucket"
  location = var.region
}

resource "google_storage_bucket_object" "cloud_function" {
  name   = "${var.function_name}-archive.zip"
  bucket = google_storage_bucket.cloud_function.name
  source = "${path.module}/index.js.zip"
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM POLICIES
# ---------------------------------------------------------------------------------------------------------------------

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project
  region         = var.region
  cloud_function = google_cloudfunctions_function.http_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

resource "google_project_iam_member" "cloud_function" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloud_function.email}"
}