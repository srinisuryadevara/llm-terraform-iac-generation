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

locals {
  project = var.gcp_project_id
  config = {
    project = local.project
    region = var.gcp_region
    bucket_name = var.gcp_bucket_name
    service_account_name = var.gcp_service_account_name
    dataflow_job_name = var.gcp_dataflow_job_name
    dataflow_template_gcs_path = var.gcp_dataflow_template_gcs_path
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

resource "google_dataflow_flex_template_run" "main" {
  name                = var.gcp_dataflow_job_name
  region              = var.gcp_region
  template_gcs_path  = var.gcp_dataflow_template_gcs_path
  service_account_email = google_service_account.dataflow.email
  staging_location    = "gs://${var.gcp_bucket_name}/staging"
}

output "gcp_dataflow_job_name" {
  value = google_dataflow_flex_template_run.main.name
}

output "gcp_service_account_email" {
  value = google_service_account.dataflow.email
}