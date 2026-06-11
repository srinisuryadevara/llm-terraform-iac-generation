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
    latest_revision = bool
    revisions       = list(string)
    percent         = number
  })
  description = "The traffic split configuration for the Cloud Run service"
}

variable "iam_members" {
  type = list(string)
  description = "The members to bind to the Cloud Run service IAM role"
}

variable "iam_role" {
  type        = string
  description = "The IAM role to bind to the Cloud Run service"
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
    percent         = var.traffic_split.percent
    latest_revision = var.traffic_split.latest_revision
    revision_name   = var.traffic_split.revisions[0]
  }

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }
  }
}

resource "google_cloud_run_service_iam_binding" "main" {
  location = var.location
  service  = google_cloud_run_service.main.name
  role     = var.iam_role
  members  = var.iam_members
}