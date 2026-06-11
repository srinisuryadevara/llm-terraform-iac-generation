provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP Region"
}

variable "service_name" {
  type        = string
  description = "Cloud Run Service Name"
}

variable "image_url" {
  type        = string
  description = "Container Image URL"
}

variable "traffic_percentages" {
  type        = map(number)
  description = "Traffic Split Percentages"
}

variable "iam_members" {
  type        = list(string)
  description = "IAM Members for Cloud Run Service"
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
    role = "roles/run.invoker"

    members = var.iam_members
  }
}

resource "google_cloud_run_service_iam_binding" "example" {
  location = google_cloud_run_service.example.location
  project  = var.project_id
  service  = google_cloud_run_service.example.name
  role     = "roles/run.invoker"
  members  = var.iam_members
}

output "service_url" {
  value = google_cloud_run_service.example.status[0].url
}