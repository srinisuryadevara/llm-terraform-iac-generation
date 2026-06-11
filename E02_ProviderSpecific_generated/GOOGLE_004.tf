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

variable "service_name" {
  type = string
}

variable "image_url" {
  type = string
}

variable "traffic_percentages" {
  type = map(number)
}

resource "google_cloud_run_service" "default" {
  name     = var.service_name
  location = var.region

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
    revision = google_cloud_run_revision.previous.name
  }
}

resource "google_cloud_run_revision" "previous" {
  service_name = google_cloud_run_service.default.name
  location     = var.region

  template {
    spec {
      containers {
        image = var.image_url
      }
    }
  }
}

resource "google_cloud_run_service_iam_binding" "default" {
  location = var.region
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  members = [
    "allUsers",
  ]
}