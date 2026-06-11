provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "dataflow_staging" {
  name     = "${var.project_id}-dataflow-staging"
  location = var.region
  force_destroy = true
}

resource "google_service_account" "dataflow_service_account" {
  account_id = "dataflow-service-account"
}

resource "google_service_account_key" "dataflow_service_account_key" {
  service_account_id = google_service_account.dataflow_service_account.id
}

resource "google_iam_role" "dataflow_worker" {
  name        = "dataflow-worker"
  title       = "Dataflow Worker"
  description = "Dataflow worker role"
}

resource "google_iam_role" "dataflow_runner" {
  name        = "dataflow-runner"
  title       = "Dataflow Runner"
  description = "Dataflow runner role"
}

resource "google_iam_policy" "dataflow_policy" {
  name        = "dataflow-policy"
  description = "Dataflow policy"

  policy_data = jsonencode({
    "bindings": [
      {
        "role": google_iam_role.dataflow_worker.name,
        "members": [
          "serviceAccount:${google_service_account.dataflow_service_account.email}",
        ]
      },
      {
        "role": google_iam_role.dataflow_runner.name,
        "members": [
          "serviceAccount:${google_service_account.dataflow_service_account.email}",
        ]
      },
    ]
  })
}

resource "google_iam_policy_assignment" "dataflow_policy_assignment" {
  name       = "dataflow-policy-assignment"
  policy     = google_iam_policy.dataflow_policy.id
  location   = var.region
  project    = var.project_id
}

resource "google_dataflow_flex_template_run" "example" {
  provider                = google
  project                 = var.project_id
  region                  = var.region
  template_gcs_path       = "gs://${google_storage_bucket.dataflow_staging.name}/template"
  parameters              = {
    "input" = "gs://${google_storage_bucket.dataflow_staging.name}/input"
  }
  service_account_email   = google_service_account.dataflow_service_account.email
  launch_parameters       = {
    "zone" = var.zone
  }
  container_spec_gcs_path = "gs://${google_storage_bucket.dataflow_staging.name}/container"
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}