provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_cloud_run_service" "default" {
  name     = var.service_name
  location = var.region
  labels = {
    environment = "dev"
    service     = var.service_name
  }

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
    revision_name   = google_cloud_run_revision.v1.name
  }
}

resource "google_cloud_run_revision" "v1" {
  service_name = google_cloud_run_service.default.name
  location     = var.region
  labels = {
    environment = "dev"
    service     = var.service_name
    revision    = "v1"
  }

  template {
    spec {
      containers {
        image = var.container_image_v1
        ports {
          container_port = var.container_port
        }
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

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type = string
}

variable "service_name" {
  type = string
}

variable "container_image" {
  type = string
}

variable "container_image_v1" {
  type = string
}

variable "container_port" {
  type = number
}

output "cloud_run_service_name" {
  value       = google_cloud_run_service.default.name
  description = "The name of the Cloud Run service"
}

output "cloud_run_service_url" {
  value       = google_cloud_run_service.default.status[0].url
  description = "The URL of the Cloud Run service"
}

output "cloud_run_revision_name" {
  value       = google_cloud_run_revision.v1.name
  description = "The name of the Cloud Run revision"
}

output "cloud_run_service_iam_binding_role" {
  value       = google_cloud_run_service_iam_binding.default.role
  description = "The role of the Cloud Run service IAM binding"
}

output "cloud_run_service_iam_binding_members" {
  value       = google_cloud_run_service_iam_binding.default.members
  description = "The members of the Cloud Run service IAM binding"
}