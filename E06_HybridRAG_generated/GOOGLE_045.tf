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
    latest_revision  = bool
    revision_name    = string
    percent          = number
  })
  description = "The traffic split configuration"
}

variable "iam_members" {
  type = list(string)
  description = "The list of IAM members to bind to the Cloud Run service"
}

variable "iam_role" {
  type        = string
  description = "The IAM role to bind to the Cloud Run service"
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_cloud_run_service" "main" {
  name     = var.service_name
  location = var.location

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
  }

  traffic {
    percent         = var.traffic_split.percent
    latest_revision = var.traffic_split.latest_revision
    revision_name   = var.traffic_split.revision_name
  }
}

resource "google_cloud_run_service_iam_binding" "main" {
  location = google_cloud_run_service.main.location
  service  = google_cloud_run_service.main.name
  role     = var.iam_role
  members  = var.iam_members
}