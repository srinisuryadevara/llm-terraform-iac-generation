provider "google" {
  version = "~> 4.0"
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  description = "The ID of the project to create the resources in"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The region to create the resources in"
}

variable "bucket_name" {
  type        = string
  description = "The name of the staging bucket"
}

variable "service_account_name" {
  type        = string
  description = "The name of the service account"
}

resource "google_storage_bucket" "staging_bucket" {
  name     = var.bucket_name
  location = var.region
  force_destroy = true
}

resource "google_service_account" "dataflow_service_account" {
  account_id = var.service_account_name
}

resource "google_service_account_key" "dataflow_service_account_key" {
  service_account_id = google_service_account.dataflow_service_account.id
}

resource "google_dataflow_flex_template_run" "dataflow_job" {
  provider            = google
  project              = var.project_id
  region               = var.region
  template_gcs_path   = "gs://${google_storage_bucket.staging_bucket.name}/template"
  parameters          = {
    "input" = "gs://${google_storage_bucket.staging_bucket.name}/input"
  }
  service_account_email = google_service_account.dataflow_service_account.email
}

resource "google_iam_role" "dataflow_worker_role" {
  name        = "dataflow-worker-role"
  title       = "Dataflow Worker Role"
  description = "Role for Dataflow workers"
}

resource "google_iam_role" "dataflow_runner_role" {
  name        = "dataflow-runner-role"
  title       = "Dataflow Runner Role"
  description = "Role for Dataflow runners"
}

resource "google_iam_policy" "dataflow_policy" {
  binding {
    role = google_iam_role.dataflow_worker_role.id
    members = [
      "serviceAccount:${google_service_account.dataflow_service_account.email}",
    ]
  }
  binding {
    role = google_iam_role.dataflow_runner_role.id
    members = [
      "serviceAccount:${google_service_account.dataflow_service_account.email}",
    ]
  }
}

resource "google_iam_policy_attachment" "dataflow_attachment" {
  name       = "dataflow-attachment"
  policy     = google_iam_policy.dataflow_policy.id
  members = [
    "serviceAccount:${google_service_account.dataflow_service_account.email}",
  ]
}