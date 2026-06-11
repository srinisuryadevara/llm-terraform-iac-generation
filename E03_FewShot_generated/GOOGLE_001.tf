provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "dataflow_staging" {
  name     = "${var.prefix}-dataflow-staging"
  location = var.region
  storage_class = "REGIONAL"
}

resource "google_service_account" "dataflow_service_account" {
  account_id = "${var.prefix}-dataflow-sa"
}

resource "google_service_account_key" "dataflow_service_account_key" {
  service_account_id = google_service_account.dataflow_service_account.id
}

resource "google_iam_role" "dataflow_worker" {
  name        = "${var.prefix}-dataflow-worker"
  title       = "${var.prefix} Dataflow Worker"
  description = "Dataflow worker role"
}

resource "google_iam_role" "dataflow_runner" {
  name        = "${var.prefix}-dataflow-runner"
  title       = "${var.prefix} Dataflow Runner"
  description = "Dataflow runner role"
}

resource "google_iam_policy" "dataflow_policy" {
  name        = "${var.prefix}-dataflow-policy"
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

resource "google_dataflow_flex_template_run" "example" {
  provider                = google
  name                    = "${var.prefix}-dataflow-run"
  template_gcs_path       = "gs://${google_storage_bucket.dataflow_staging.name}/template"
  parameters              = {
    "input" = "gs://${google_storage_bucket.dataflow_staging.name}/input"
  }
  service_account_email   = google_service_account.dataflow_service_account.email
  staging_location        = "gs://${google_storage_bucket.dataflow_staging.name}/staging"
  container_spec_gcs_path = "gs://${google_storage_bucket.dataflow_staging.name}/container"
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "prefix" {
  type = string
}