terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.gcp_bucket_name
  }
}

provider "google" {
  project     = var.gcp_project_id
  region      = var.gcp_region
}

provider "google-beta" {
  project     = var.gcp_project_id
  region      = var.gcp_region
}

variable "gcp_project_id" {}
variable "gcp_region" {
  default = "us-central1"
}
variable "gcp_bucket_name" {}
variable "gcp_service_account_name" {}
variable "gcp_dataflow_job_name" {}
variable "gcp_dataflow_template_gcs_path" {}
variable "gcp_dataflow_parameters" {
  type = map(string)
}

locals {
  project = var.gcp_project_id
  config = {
    project = local.project
    region = var.gcp_region
    bucket_name = var.gcp_bucket_name
    service_account_name = var.gcp_service_account_name
    dataflow_job_name = var.gcp_dataflow_job_name
    dataflow_template_gcs_path = var.gcp_dataflow_template_gcs_path
    dataflow_parameters = var.gcp_dataflow_parameters
  }
}

resource "google_storage_bucket" "staging" {
  name     = var.gcp_bucket_name
  location = var.gcp_region
}

resource "google_service_account" "dataflow" {
  account_id = var.gcp_service_account_name
}

resource "google_service_account_key" "dataflow" {
  service_account_id = google_service_account.dataflow.id
}

resource "google_iam_role" "dataflow" {
  name        = "dataflow-${var.gcp_service_account_name}"
  title       = "Dataflow Service Account Role"
  description = "Role for Dataflow service account"
  permissions = [
    "dataflow.jobs.create",
    "dataflow.jobs.get",
    "dataflow.jobs.list",
    "dataflow.jobs.update",
    "dataflow.jobs.delete",
    "dataflow.templates.get",
    "dataflow.templates.list",
    "dataflow.templates.create",
    "dataflow.templates.update",
    "dataflow.templates.delete",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.create",
    "storage.objects.update",
    "storage.objects.delete",
  ]
}

resource "google_iam_role_binding" "dataflow" {
  role = google_iam_role.dataflow.id
  members = [
    "serviceAccount:${google_service_account.dataflow.email}",
  ]
}

resource "google_dataflow_flex_template_run" "example" {
  provider                = google-beta
  project                 = var.gcp_project_id
  region                  = var.gcp_region
  template_gcs_path       = var.gcp_dataflow_template_gcs_path
  parameters              = var.gcp_dataflow_parameters
  service_account_email   = google_service_account.dataflow.email
  launch_parameters {
    container_spec_gcs_path = "${var.gcp_dataflow_template_gcs_path}/container_spec.json"
  }
  depends_on = [
    google_service_account.dataflow,
    google_service_account_key.dataflow,
    google_iam_role.dataflow,
    google_iam_role_binding.dataflow,
  ]
}