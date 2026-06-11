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
  labels = {
    environment = "production"
    service     = var.service_name
  }

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
  members = [
    "allUsers",
  ]
}

output "cloud_run_service_id" {
  value = google_cloud_run_service.default.id
}

output "cloud_run_service_url" {
  value = google_cloud_run_service.default.status[0].url
}

output "cloud_run_service_iam_binding_id" {
  value = google_cloud_run_service_iam_binding.default.id
}