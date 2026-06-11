variable "project_id" {
  type = string
}

variable "location" {
  type = string
}

variable "service_name" {
  type = string
}

variable "image_url" {
  type = string
}

variable "traffic_percentages" {
  type = map(number)
}

variable "role" {
  type = string
}

variable "members" {
  type = list(string)
}

provider "google" {
  project = var.project_id
  region  = var.location
}

resource "google_cloud_run_service" "main" {
  name     = var.service_name
  location = var.location

  template {
    spec {
      containers {
        image = var.image_url
      }
    }
  }

  traffic {
    percent         = var.traffic_percentages["latest"]
    latest_revision = true
  }

  traffic {
    percent = var.traffic_percentages["previous"]
    revision_name = google_cloud_run_revision.previous.name
  }
}

resource "google_cloud_run_revision" "previous" {
  service_name = google_cloud_run_service.main.name
  location     = var.location
}

resource "google_cloud_run_service_iam_binding" "binding" {
  location = var.location
  service  = google_cloud_run_service.main.name
  role     = var.role
  members  = var.members
}

resource "google_service_account" "service_account" {
  account_id = "cloud-run-service-account"
}

resource "google_project_iam_binding" "project_binding" {
  project = var.project_id
  role    = var.role
  members = var.members
}