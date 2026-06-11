variable "project_id" {
  type        = string
  description = "The ID of the project to create the resources in"
}

variable "location" {
  type        = string
  description = "The location to create the resources in"
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

variable "iam_roles" {
  type = list(string)
  description = "The list of IAM roles to bind to the service"
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

resource "google_cloud_run_revision" "canary" {
  service_name = google_cloud_run_service.main.name
  container {
    image = "gcr.io/cloudrun/hello"
    ports {
      container_port = 8080
    }
  }
}

resource "google_cloud_run_service_iam_binding" "main" {
  location = var.location
  service  = google_cloud_run_service.main.name
  role     = var.iam_roles[0]
  members  = var.iam_members
}