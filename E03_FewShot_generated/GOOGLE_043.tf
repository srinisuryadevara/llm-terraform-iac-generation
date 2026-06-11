provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "dataflow_staging" {
  name                        = "${var.project_id}-dataflow-staging"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
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
  description = "Role for Dataflow workers"
}

resource "google_iam_role" "dataflow_runner" {
  name        = "dataflow-runner"
  title       = "Dataflow Runner"
  description = "Role for Dataflow runners"
}

resource "google_iam_member" "dataflow_worker" {
  role   = google_iam_role.dataflow_worker.id
  member = "serviceAccount:${google_service_account.dataflow_service_account.email}"
}

resource "google_iam_member" "dataflow_runner" {
  role   = google_iam_role.dataflow_runner.id
  member = "serviceAccount:${google_service_account.dataflow_service_account.email}"
}

resource "google_dataflow_flex_template_run" "example" {
  provider                = google
  project                 = var.project_id
  region                  = var.region
  template_gcs_path       = "gs://${google_storage_bucket.dataflow_staging.name}/template"
  parameters              = {
    "input" = "gs://${google_storage_bucket.dataflow_staging.name}/input"
    "output" = "gs://${google_storage_bucket.dataflow_staging.name}/output"
  }
  service_account_email   = google_service_account.dataflow_service_account.email
  container_spec_gcs_path = "gs://${google_storage_bucket.dataflow_staging.name}/container-spec"
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}