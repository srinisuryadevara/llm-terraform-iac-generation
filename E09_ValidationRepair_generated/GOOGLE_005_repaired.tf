# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Create a Cloud Run service
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

# Create a Cloud Run revision
resource "google_cloud_run_revision" "v1" {
  service_name = google_cloud_run_service.default.name
  location     = var.region
  labels = {
    environment = "production"
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

# Create an IAM binding for the Cloud Run service
resource "google_cloud_run_service_iam_binding" "default" {
  location = var.region
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  members = [
    "allUsers",
  ]
}

# Output key resource attributes
output "cloud_run_service_name" {
  value = google_cloud_run_service.default.name
}

output "cloud_run_service_url" {
  value = google_cloud_run_service.default.status[0].url
}

output "cloud_run_revision_name" {
  value = google_cloud_run_revision.v1.name
}

output "cloud_run_service_iam_binding_role" {
  value = google_cloud_run_service_iam_binding.default.role
}

# Define input variables
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

variable "container_image_v1" {
  type        = string
}

variable "container_port" {
  type        = number
}