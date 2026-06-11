variable "project_id" {
  type        = string
  description = "The ID of the project to create the Cloud Run service in"
}

variable "location" {
  type        = string
  description = "The location to create the Cloud Run service in"
}

variable "service_name" {
  type        = string
  description = "The name of the Cloud Run service"
}

variable "traffic_split" {
  type = object({
    latest = number
    tagged = number
  })
  description = "The traffic split configuration"
}

variable "iam_members" {
  type        = list(string)
  description = "The members to bind to the Cloud Run service IAM role"
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_cloud_run_service" "main" {
  name     = var.service_name
  location = var.location

  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "100"
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
    percent = var.traffic_split.tagged
    url     = "tag:latest"
  }
}

resource "google_cloud_run_service_iam_binding" "binding" {
  location = google_cloud_run_service.main.location
  project  = google_cloud_run_service.main.project
  service  = google_cloud_run_service.main.name
  role     = "roles/run.invoker"
  members  = var.iam_members
}