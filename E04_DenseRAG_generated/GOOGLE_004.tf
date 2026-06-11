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
    latest_revision = number
    revision_name   = string
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
  version = "~> 4.0"
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
    percent         = var.traffic_split.latest_revision
    latest_revision = true
  }

  traffic {
    percent         = 100 - var.traffic_split.latest_revision
    revision_name   = var.traffic_split.revision_name
  }
}

resource "google_cloud_run_service_iam_binding" "main" {
  location = google_cloud_run_service.main.location
  service  = google_cloud_run_service.main.name
  role     = var.iam_roles[0]
  members  = var.iam_members
}

resource "google_cloud_run_service_iam_member" "main" {
  location = google_cloud_run_service.main.location
  service  = google_cloud_run_service.main.name
  role     = var.iam_roles[0]
  member   = var.iam_members[0]
}