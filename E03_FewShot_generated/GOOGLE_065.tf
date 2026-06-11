provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_cloud_run_service" "default" {
  name     = var.service_name
  location = var.region

  template {
    spec {
      containers {
        image = var.container_image
        ports {
          container_port = var.container_port
        }
      }
    }
  }

  traffic {
    percent         = 50
    latest_revision = true
  }

  traffic {
    percent         = 50
    revision_name   = google_cloud_run_service.default.template[0].spec[0].containers[0].image
  }
}

resource "google_cloud_run_service_iam_binding" "default" {
  location = google_cloud_run_service.default.location
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  members = [
    "allUsers",
  ]
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
}

variable "service_name" {
  type        = string
}

variable "container_image" {
  type        = string
}

variable "container_port" {
  type        = number
}