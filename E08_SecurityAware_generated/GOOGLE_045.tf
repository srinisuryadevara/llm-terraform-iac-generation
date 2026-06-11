provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "service_name" {
  type        = string
  description = "Cloud Run service name"
}

variable "image_url" {
  type        = string
  description = "Container image URL"
}

variable "traffic_percentages" {
  type        = map(number)
  description = "Traffic split percentages"
}

variable "iam_members" {
  type        = list(string)
  description = "IAM members to bind to the service"
}

variable "iam_roles" {
  type        = list(string)
  description = "IAM roles to bind to the service"
}

resource "google_cloud_run_service" "example" {
  name     = var.service_name
  location = var.region

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
    revision_name = "previous"
  }

  depends_on = [google_cloud_run_service_iam_policy.example]
}

resource "google_cloud_run_service_iam_policy" "example" {
  location = google_cloud_run_service.example.location
  project  = var.project_id
  service  = google_cloud_run_service.example.name

  policy_data = data.google_iam_policy.example.policy_data
}

data "google_iam_policy" "example" {
  binding {
    role = var.iam_roles[0]

    members = var.iam_members
  }
}

resource "google_cloud_run_service_iam_binding" "example" {
  location = google_cloud_run_service.example.location
  project  = var.project_id
  service  = google_cloud_run_service.example.name
  role     = var.iam_roles[0]
  members  = var.iam_members
}

output "service_url" {
  value = google_cloud_run_service.example.status[0].url
}