terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.gcp_bucket
  }
}

variable "gcp_project" {}
variable "gcp_region" {
  default = "us-central1"
}
variable "gcp_bucket" {}
variable "gcp_service_account_key" {}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  credentials = var.gcp_service_account_key
}

provider "google-beta" {
  project = var.gcp_project
  region  = var.gcp_region
  credentials = var.gcp_service_account_key
}

locals {
  project = var.gcp_project
  config = {
    project = local.project
    region = var.gcp_region
    bucket = var.gcp_bucket
  }
}

resource "google_storage_bucket" "staging" {
  name     = "${local.project}-staging-bucket"
  location = var.gcp_region
}

resource "google_service_account" "dataflow" {
  account_id = "dataflow-service-account"
}

resource "google_service_account_key" "dataflow" {
  service_account_id = google_service_account.dataflow.id
}

resource "google_dataflow_job" "example" {
  name                = "example-dataflow-job"
  template_gcs_path  = "gs://${google_storage_bucket.staging.name}/dataflow-template"
  temp_gcs_location  = "gs://${google_storage_bucket.staging.name}/temp"
  service_account_email = google_service_account.dataflow.email
  machine_type        = "n1-standard-1"
  max_workers         = 5
  parameters = {
    input = "gs://${google_storage_bucket.staging.name}/input"
    output = "gs://${google_storage_bucket.staging.name}/output"
  }
}

output "staging_bucket_name" {
  value = google_storage_bucket.staging.name
}

output "dataflow_job_id" {
  value = google_dataflow_job.example.id
}

output "dataflow_job_name" {
  value = google_dataflow_job.example.name
}