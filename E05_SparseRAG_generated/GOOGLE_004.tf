variable "project_id" {
  type        = string
  description = "The ID of the project to deploy to"
}

variable "location" {
  type        = string
  description = "The location to deploy to"
}

variable "service_name" {
  type        = string
  description = "The name of the Cloud Run service"
}

variable "image_url" {
  type        = string
  description = "The URL of the container image to deploy"
}

variable "traffic_percentages" {
  type        = map(number)
  description = "A map of traffic percentages for each revision"
}

variable "iam_members" {
  type        = list(string)
  description = "A list of IAM members to bind to the service"
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

  dynamic "traffic" {
    for_each = var.traffic_percentages
    content {
      percent = traffic.value
      revision = google_cloud_run_revision.default[traffic.key].name
    }
  }
}

resource "google_cloud_run_revision" "default" {
  for_each = var.traffic_percentages
  service  = google_cloud_run_service.default.name

  template {
    spec {
      containers {
        image = var.image_url
      }
    }
  }
}

resource "google_cloud_run_service_iam_member" "default" {
  for_each = toset(var.iam_members)
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = each.value
}

resource "google_cloud_run_service_iam_member" "service_account" {
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = local.service_account_email
}