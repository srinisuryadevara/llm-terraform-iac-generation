terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.gcp_bucket
  }
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type    = string
  default = "us-central1"
}

variable "gcp_bucket" {
  type = string
}

variable "gcp_service_account_email" {
  type = string
}

variable "gcp_dataflow_job_name" {
  type = string
}

variable "gcp_dataflow_template_gcs_path" {
  type = string
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

provider "google-beta" {
  project = var.gcp_project
  region  = var.gcp_region
}

resource "google_storage_bucket" "staging" {
  name     = "${var.gcp_project}-dataflow-staging"
  location = var.gcp_region
}

resource "google_service_account" "dataflow" {
  account_id = "dataflow-service-account"
}

resource "google_service_account_key" "dataflow" {
  service_account_id = google_service_account.dataflow.id
}

resource "google_iam_role" "dataflow" {
  name        = "dataflow-role"
  title       = "Dataflow Role"
  description = "Role for Dataflow service account"
}

resource "google_iam_role_assignment" "dataflow" {
  role       = google_iam_role.dataflow.id
  members    = ["serviceAccount:${google_service_account.dataflow.email}"]
  condition {
    title       = "Dataflow Condition"
    description = "Condition for Dataflow service account"
    expression  = "request.time < timestamp('2025-01-01T00:00:00Z')"
  }
}

resource "google_dataflow_flex_template" "example" {
  provider            = google-beta
  project              = var.gcp_project
  region               = var.gcp_region
  template_gcs_path    = var.gcp_dataflow_template_gcs_path
  service_account_email = google_service_account.dataflow.email
  staging_location      = "gs://${google_storage_bucket.staging.name}/staging"
  parameters = {
    param1 = "value1"
    param2 = "value2"
  }
  container_spec_gcs_path = "gs://${google_storage_bucket.staging.name}/container-spec.json"
}

resource "google_dataflow_job" "example" {
  provider            = google-beta
  project              = var.gcp_project
  region               = var.gcp_region
  name                 = var.gcp_dataflow_job_name
  template_gcs_path    = var.gcp_dataflow_template_gcs_path
  service_account_email = google_service_account.dataflow.email
  parameters = {
    param1 = "value1"
    param2 = "value2"
  }
  container_spec_gcs_path = "gs://${google_storage_bucket.staging.name}/container-spec.json"
}