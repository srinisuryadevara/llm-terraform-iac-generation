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
  handler     = var.function_handler
  service_account_email = google_service_account.cloud_function.email
  available_memory_mb   = 128
  trigger {
    http_method = "GET"
    url_path    = "/"
  }
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project
  region         = var.region
  cloud_function = google_cloudfunctions_function.http_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

resource "google_iam_policy" "cloud_function_policy" {
  binding {
    role = "roles/cloudfunctions.serviceAgent"
    members = [
      "serviceAccount:${google_service_account.cloud_function.email}",
    ]
  }
}

resource "google_service_account_key" "cloud_function_key" {
  service_account_id = google_service_account.cloud_function.id
}

resource "google_iam_role" "cloud_function_role" {
  name        = "${var.function_name}-role"
  title       = "${var.function_name} Role"
  description = "Role for ${var.function_name} Cloud Function"
  permissions = [
    "cloudfunctions.functions.call",
  ]
}

resource "google_iam_role_assignment" "cloud_function_assignment" {
  role       = google_iam_role.cloud_function_role.id
  members    = [
    "serviceAccount:${google_service_account.cloud_function.email}",
  ]
}