terraform {
  required_version = ">= 0.12.8"
}

# VARIABLES
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
variable "service_account_email" {}
variable "service_account_key" {}

# PROVIDERS
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

# SERVICE ACCOUNT
resource "google_service_account" "cloud_function" {
  account_id = var.function_name
}

resource "google_service_account_key" "cloud_function" {
  service_account_id = google_service_account.cloud_function.id
}

# CLOUD FUNCTION
resource "google_cloudfunctions_function" "http_function" {
  name        = var.function_name
  runtime     = var.function_runtime
  handler     = var.function_handler
  entry_point = "index"
  region      = var.region

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.cloud_function.name
  source_archive_object = google_storage_bucket_object.cloud_function.name
  trigger_http {
    security_level = "SECURE_OPTIONAL"
  }
}

# STORAGE BUCKET
resource "google_storage_bucket" "cloud_function" {
  name     = var.function_name
  location = var.region
}

# STORAGE OBJECT
resource "google_storage_bucket_object" "cloud_function" {
  name   = var.function_name
  bucket = google_storage_bucket.cloud_function.name
  source = "${path.module}/index.js"
}

# IAM POLICY
resource "google_cloudfunctions_function_iam_policy" "cloud_function" {
  name        = google_cloudfunctions_function.http_function.name
  policy_data = data.google_iam_policy.cloud_function.policy_data
}

data "google_iam_policy" "cloud_function" {
  binding {
    role = "roles/cloudfunctions.invoker"
    members = [
      "allUsers",
    ]
  }
}

# IAM BINDING
resource "google_project_iam_binding" "cloud_function" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  members = [
    "serviceAccount:${google_service_account.cloud_function.email}",
  ]
}