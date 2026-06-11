variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "service_name" {
  type = string
}

variable "service_account_email" {
  type = string
}

variable "container_image" {
  type = string
}

variable "container_port" {
  type = number
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_service_account" "cloud_run" {
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Service Account"
}

resource "google_cloud_run_service" "main" {
  name     = var.service_name
  location = var.region

  template {
    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" = "default"
        "run.googleapis.com/vpc-access-egress" = "all-traffic"
        "autoscaling.knative.dev/maxScale"     = "10"
      }
    }

    spec {
      service_account_name  = google_service_account.cloud_run.email
      container_concurrency = 80
      containers {
        image = var.container_image
        ports {
          container_port = var.container_port
        }
        env {
          name  = "EXAMPLE_VAR"
          value = "example-value"
        }
      }
    }
  }
  metadata {
    annotations = {
      "example-annotation" = "example-annotation-value"
    }
  }
}

resource "google_project_iam_member" "cloud_run_invoker" {
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}