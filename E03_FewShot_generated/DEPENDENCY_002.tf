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

resource "google_service_account" "cloud_run_service_account" {
  account_id = "cloud-run-service-account"
}

resource "google_service_account_key" "cloud_run_service_account_key" {
  service_account_id = google_service_account.cloud_run_service_account.id
}

resource "google_iam_policy" "cloud_run_service_account_policy" {
  name        = "cloud-run-service-account-policy"
  description = "Policy for Cloud Run service account"

  policy_data = jsonencode({
    "version" : "2012-10-17",
    "statement" : [
      {
        "sid" : "CloudRunServiceAccountPolicy",
        "effect" : "Allow",
        "action" : [
          "run.services.get",
          "run.services.list",
          "run.services.update",
        ],
        "resource" : "*"
      },
    ]
  })
}

resource "google_iam_policy_attachment" "cloud_run_service_account_attachment" {
  name       = "cloud-run-service-account-attachment"
  policy     = google_iam_policy.cloud_run_service_account_policy.id
  members    = ["serviceAccount:${google_service_account.cloud_run_service_account.email}"]
}

resource "google_cloud_run_service" "example" {
  name     = "cloud-run-example"
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.cloud_run_service_account.email
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}