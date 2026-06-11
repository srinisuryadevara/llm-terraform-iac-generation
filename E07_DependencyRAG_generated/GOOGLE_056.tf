provider "google" {
  version = "~> 2.0"
  region      = var.region
}

variable "region" {
  default = "us-central1"
}

variable "project" {
  default = "my-project"
}

variable "function_name" {
  default = "my-function"
}

variable "runtime" {
  default = "nodejs14"
}

variable "service_account_email" {
  default = "my-service-account@my-project.iam.gserviceaccount.com"
}

resource "google_service_account" "service_account" {
  account_id = "my-service-account"
  project    = var.project
}

resource "google_service_account_key" "service_account_key" {
  service_account_id = google_service_account.service_account.id
}

resource "google_cloudfunctions_function" "function" {
  name        = var.function_name
  runtime     = var.runtime
  region      = var.region
  service_account_email = google_service_account.service_account.email
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project
  region         = var.region
  cloud_function = google_cloudfunctions_function.function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

resource "google_cloudfunctions_function" "function_with_http_trigger" {
  name        = "${var.function_name}-http-trigger"
  runtime     = var.runtime
  region      = var.region
  service_account_email = google_service_account.service_account.email
  trigger_http {
    security_level = "SECURE_ALWAYS"
  }
}