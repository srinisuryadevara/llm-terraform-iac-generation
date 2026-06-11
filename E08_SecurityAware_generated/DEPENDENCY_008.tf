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
  description = "The region of the project"
}

variable "service_account_email" {
  type        = string
  description = "The email of the service account"
}

variable "cloud_run_service_name" {
  type        = string
  description = "The name of the Cloud Run service"
}

variable "cloud_run_container_image" {
  type        = string
  description = "The container image of the Cloud Run service"
}

resource "google_service_account" "cloud_run_service_account" {
  account_id = "cloud-run-service-account"
  description = "Service account for Cloud Run service"
  tags = {
    environment = "production"
  }
}

resource "google_service_account_key" "cloud_run_service_account_key" {
  service_account_id = google_service_account.cloud_run_service_account.id
}

resource "google_iam_policy" "cloud_run_service_account_policy" {
  name        = "cloud-run-service-account-policy"
  description = "Policy for Cloud Run service account"

  policy_data = <<EOF
{
  "version": 3,
  "bindings": [
    {
      "role": "roles/run.serviceAgent",
      "members": [
        "serviceAccount:${google_service_account.cloud_run_service_account.email}"
      ]
    }
  ]
}
EOF
}

resource "google_iam_role" "cloud_run_service_account_role" {
  name        = "cloud-run-service-account-role"
  description = "Role for Cloud Run service account"
  permissions = [
    "run.services.get",
    "run.services.list",
    "run.services.update",
  ]
}

resource "google_cloud_run_service" "cloud_run_service" {
  name     = var.cloud_run_service_name
  location = var.region
  project  = var.project_id

  template {
    spec {
      service_account_name = google_service_account.cloud_run_service_account.email
      containers {
        image = var.cloud_run_container_image
        ports {
          container_port = 8080
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_iam_policy.cloud_run_service_account_policy,
    google_iam_role.cloud_run_service_account_role,
  ]

  tags = {
    environment = "production"
  }
}

resource "google_cloud_run_service_iam_policy" "cloud_run_service_iam_policy" {
  location = google_cloud_run_service.cloud_run_service.location
  project  = google_cloud_run_service.cloud_run_service.project
  service  = google_cloud_run_service.cloud_run_service.name

  policy_data = <<EOF
{
  "version": 3,
  "bindings": [
    {
      "role": "roles/run.serviceAgent",
      "members": [
        "serviceAccount:${google_service_account.cloud_run_service_account.email}"
      ]
    }
  ]
}
EOF
}