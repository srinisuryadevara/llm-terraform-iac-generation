variable "project" {
  type        = string
  description = "The ID of the project to deploy to"
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
  description = "The URL of the container image to deploy"
}

variable "port" {
  type        = number
  description = "The port that the container listens on"
}

variable "max_instances" {
  type        = number
  description = "The maximum number of instances to run"
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_service_account" "cloud_run" {
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Service Account"
}

resource "google_project_iam_member" "cloud_run_invoker" {
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

resource "google_cloud_run_service" "main" {
  name     = var.service_name
  location = var.region

  template {
    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-egress" = "all-traffic"
        "autoscaling.knative.dev/maxScale"     = var.max_instances
      }
    }

    spec {
      service_account_name  = google_service_account.cloud_run.email
      container_concurrency = 80
      containers {
        image = var.image_url
        ports {
          container_port = var.port
        }
      }
    }
  }
}