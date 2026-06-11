variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "location" {
  type        = string
  description = "The location of the Cloud Run service"
}

variable "service_name" {
  type        = string
  description = "The name of the Cloud Run service"
}

variable "image_url" {
  type        = string
  description = "The URL of the container image"
}

variable "traffic_percentages" {
  type        = map(number)
  description = "A map of traffic percentages for each revision"
}

variable "iam_members" {
  type        = list(string)
  description = "A list of IAM members to bind to the Cloud Run service"
}

locals {
  service_account_email = "service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_cloud_run_service" "default" {
  name     = var.service_name
  location = var.location

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
    revision_name = google_cloud_run_revision.previous.name
  }
}

resource "google_cloud_run_revision" "previous" {
  service_name = google_cloud_run_service.default.name
  location     = var.location

  template {
    spec {
      containers {
        image = var.image_url
      }
    }
  }
}

resource "google_cloud_run_service_iam_member" "invoker" {
  location = var.location
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "viewer" {
  count   = length(var.iam_members)
  location = var.location
  service  = google_cloud_run_service.default.name
  role     = "roles/run.viewer"
  member   = var.iam_members[count.index]
}