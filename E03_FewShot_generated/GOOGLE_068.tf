provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "dataflow_staging" {
  name     = "${var.project_id}-dataflow-staging"
  location = var.region
  storage_class = "REGIONAL"
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
  description = "Role for Dataflow runner"
}

resource "google_iam_member" "dataflow_worker" {
  role    = google_iam_role.dataflow_worker.id
  member  = "serviceAccount:${google_service_account.dataflow_service_account.email}"
}

resource "google_iam_member" "dataflow_runner" {
  role    = google_iam_role.dataflow_runner.id
  member  = "serviceAccount:${google_service_account.dataflow_service_account.email}"
}

resource "google_dataflow_job" "example" {
  name                = "example-dataflow-job"
  template_gcs_path = "gs://${google_storage_bucket.dataflow_staging.name}/template"
  temp_gcs_location   = "gs://${google_storage_bucket.dataflow_staging.name}/temp"
  service_account_email = google_service_account.dataflow_service_account.email
  machine_type        = "n1-standard-1"
  max_instances       = 3
  parameters = {
    input = "gs://${google_storage_bucket.dataflow_staging.name}/input"
    output = "gs://${google_storage_bucket.dataflow_staging.name}/output"
  }
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "us-central1"
}