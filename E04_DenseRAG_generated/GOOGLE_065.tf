# Configure the Google Cloud Provider
provider "google" {
  version = "~> 4.0"
  project = var.project_id
  region  = var.region
}

# Define variables
variable "project_id" {
  type        = string
  description = "The ID of the project to deploy to"
}

variable "region" {
  type        = string
  description = "The region to deploy to"
}

variable "service_name" {
  type        = string
  description = "The name of the Cloud Run service"
}

variable "traffic_split" {
  type = object({
    latest = number
    canary = number
  })
  description = "The traffic split configuration"
}

variable "iam_members" {
  type = list(string)
  description = "The list of IAM members to bind to the service"
}

# Create a Cloud Run service
resource "google_cloud_run_service" "main" {
  name     = var.service_name
  location = var.region

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "10"
      }
    }

    spec {
      container_concurrency = 80
      containers {
        image = "gcr.io/cloudrun/hello"
        ports {
          container_port = 8080
        }
      }
    }
  }

  traffic {
    percent         = var.traffic_split.latest
    latest_revision = true
  }

  traffic {
    percent = var.traffic_split.canary
    revision = google_cloud_run_revision.canary.name
  }
}

# Create a Cloud Run revision
resource "google_cloud_run_revision" "canary" {
  name   = "${var.service_name}-canary"
  service = google_cloud_run_service.main.name
  location = var.region

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "10"
      }
    }

    spec {
      container_concurrency = 80
      containers {
        image = "gcr.io/cloudrun/hello-canary"
        ports {
          container_port = 8080
        }
      }
    }
  }
}

# Create an IAM binding for the service
resource "google_cloud_run_service_iam_binding" "main" {
  location = var.region
  service  = google_cloud_run_service.main.name
  role     = "roles/run.invoker"
  members  = var.iam_members
}