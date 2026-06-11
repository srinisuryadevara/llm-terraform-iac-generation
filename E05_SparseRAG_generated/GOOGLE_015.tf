terraform {
  required_version = ">= 0.12.7"
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
  region      = var.region

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.cloud_function.name
  source_archive_object = google_storage_bucket_object.cloud_function.name
  trigger_http          = true

  service_account_email = var.service_account_email
}

# ---------------------------------------------------------------------------------------------------------------------
# STORAGE BUCKET
# ---------------------------------------------------------------------------------------------------------------------

resource "google_storage_bucket" "cloud_function" {
  name     = "${var.function_name}-bucket"
  location = var.region
}

# ---------------------------------------------------------------------------------------------------------------------
# STORAGE BUCKET OBJECT
# ---------------------------------------------------------------------------------------------------------------------

resource "google_storage_bucket_object" "cloud_function" {
  name   = "${var.function_name}-object"
  bucket = google_storage_bucket.cloud_function.name
  source = "${path.module}/index.js"
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM POLICY
# ---------------------------------------------------------------------------------------------------------------------

resource "google_cloudfunctions_function_iam_policy" "http_function" {
  cloud_function_id = google_cloudfunctions_function.http_function.id
  policy            = google_iam_policy.cloud_function.policy
}

resource "google_iam_policy" "cloud_function" {
  name        = "${var.function_name}-policy"
  description = "Cloud Function IAM Policy"

  policy      = <<EOF
{
  "version": 3,
  "bindings": [
    {
      "role": "roles/cloudfunctions.invoker",
      "members": [
        "allUsers"
      ]
    }
  ]
}
EOF
}