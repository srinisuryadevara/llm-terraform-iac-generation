provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to deploy to"
}

variable "service_account_email" {
  type        = string
  description = "The email of the service account"
}

resource "google_service_account" "cloud_run_service_account" {
  account_id = "cloud-run-service-account"
}

resource "google_service_account_key" "cloud_run_service_account_key" {
  service_account_id = google_service_account.cloud_run_service_account.id
}

resource "google_cloud_run_service" "example" {
  name     = "example-service"
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.cloud_run_service_account.email
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}