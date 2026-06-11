variable "project_id" {
  type        = string
  description = "The ID of the project to deploy to"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The region to deploy to"
}

variable "service_name" {
  type        = string
  description = "The name of the Cloud Run service"
}

variable "traffic_split" {
  type        = map(number)
  description = "The traffic split configuration"
}

variable "iam_members" {
  type        = list(string)
  description = "The list of IAM members to bind to the service"
}

variable "iam_roles" {
  type        = list(string)
  description = "The list of IAM roles to bind to the service"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_cloud_run_service" "main" {
  name     = var.service_name
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
  }

  traffic {
    percent         = var.traffic_split["0"]
    latest_revision = true
  }

  traffic {
    percent = var.traffic_split["1"]
    revision_name = "my-revision"
  }
}

resource "google_cloud_run_service_iam_binding" "main" {
  location = var.region
  service  = google_cloud_run_service.main.name
  role     = var.iam_roles[0]
  members  = var.iam_members
}