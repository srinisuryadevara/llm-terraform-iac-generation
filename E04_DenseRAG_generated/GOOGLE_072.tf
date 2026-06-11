terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.gcp_bucket
  }
}

provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
}

provider "google-beta" {
  project     = var.gcp_project
  region      = var.gcp_region
}

variable "gcp_project" {}
variable "gcp_region" {
  default = "us-central1"
}
variable "gcp_bucket" {}

locals {
  dataflow_service_account = "dataflow-service-account"
  dataflow_staging_bucket = "dataflow-staging-bucket"
}

resource "google_storage_bucket" "dataflow_staging_bucket" {
  name     = local.dataflow_staging_bucket
  location = var.gcp_region
}

resource "google_service_account" "dataflow_service_account" {
  account_id = local.dataflow_service_account
}

resource "google_service_account_key" "dataflow_service_account_key" {
  service_account_id = google_service_account.dataflow_service_account.id
}

resource "google_iam_role" "dataflow_worker" {
  name        = "dataflow-worker"
  title       = "Dataflow Worker"
  description = "Role for Dataflow workers"
}

resource "google_iam_role" "dataflow_admin" {
  name        = "dataflow-admin"
  title       = "Dataflow Admin"
  description = "Role for Dataflow admins"
}

resource "google_iam_binding" "dataflow_worker_binding" {
  role = google_iam_role.dataflow_worker.id
  members = [
    "serviceAccount:${google_service_account.dataflow_service_account.email}",
  ]
}

resource "google_iam_binding" "dataflow_admin_binding" {
  role = google_iam_role.dataflow_admin.id
  members = [
    "serviceAccount:${google_service_account.dataflow_service_account.email}",
  ]
}

resource "google_dataflow_job" "example" {
  name                = "example-dataflow-job"
  template_gcs_path  = "gs://${local.dataflow_staging_bucket}/dataflow-template"
  temp_gcs_location  = "gs://${local.dataflow_staging_bucket}/temp"
  service_account_email = google_service_account.dataflow_service_account.email
  machine_type        = "n1-standard-1"
  max_workers         = 5
  num_workers         = 3
  on_delete           = "cancel"
  parameters = {
    input = "gs://${local.dataflow_staging_bucket}/input"
    output = "gs://${local.dataflow_staging_bucket}/output"
  }
}