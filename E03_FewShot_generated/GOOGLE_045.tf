provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "service_name" {
  type        = string
  sensitive   = true
}

variable "image_url" {
  type        = string
  sensitive   = true
}

variable "traffic_percentages" {
  type        = map(number)
  sensitive   = true
}

variable "iam_members" {
  type        = list(string)
  sensitive   = true
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
    revision = google_cloud_run_service.default.template.spec.container[0].image
  }
}

resource "google_cloud_run_service_iam_binding" "default" {
  location = google_cloud_run_service.default.location
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  members  = var.iam_members
}