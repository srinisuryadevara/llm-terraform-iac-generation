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
  account_id = var.service_account_email
  labels = {
    environment = "dev"
    application = "cloudrun"
  }
}

resource "google_cloud_run_service" "default" {
  name     = "cloudrun-srv"
  location = var.region
  labels = {
    environment = "dev"
    application = "cloudrun"
  }

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

output "cloud_run_service_name" {
  value = google_cloud_run_service.default.name
}

output "cloud_run_service_url" {
  value = google_cloud_run_service.default.status[0].url
}

output "cloud_run_service_account_email" {
  value = google_service_account.cloud_run_service_account.email
}