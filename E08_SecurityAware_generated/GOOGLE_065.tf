provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region to deploy to"
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
  type = object({
    latest = number
    canary = number
  })
  description = "The traffic percentages for the latest and canary revisions"
}

variable "iam_members" {
  type = list(string)
  description = "The list of IAM members to bind to the Cloud Run service"
}

resource "google_cloud_run_service" "default" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  template {
    spec {
      containers {
        image = var.image_url
      }
    }
  }

  traffic {
    percent         = var.traffic_percentages.latest
    latest_revision = true
  }

  traffic {
    percent = var.traffic_percentages.canary
    revision = google_cloud_run_revision.canary.name
  }

  depends_on = [google_cloud_run_revision.canary]
}

resource "google_cloud_run_revision" "canary" {
  service  = google_cloud_run_service.default.name
  location = var.region
  project  = var.project_id

  template {
    spec {
      containers {
        image = var.image_url
      }
    }
  }
}

resource "google_cloud_run_service_iam_binding" "default" {
  location = var.region
  project  = var.project_id
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  members  = var.iam_members
}

resource "google_cloud_run_service_iam_policy" "default" {
  location = var.region
  project  = var.project_id
  service  = google_cloud_run_service.default.name
  policy   = data.google_iam_policy.default.policy_data
}

data "google_iam_policy" "default" {
  binding {
    role = "roles/run.invoker"
    members = var.iam_members
  }
}

output "service_url" {
  value = google_cloud_run_service.default.status[0].url
}