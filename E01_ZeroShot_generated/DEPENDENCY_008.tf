provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "service_account_email" {
  type = string
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