provider "google" {
  version = "~> 2.0"
  region  = var.region
}

variable "region" {
  default = "us-central1"
}

variable "project" {
  default = "my-project"
}

variable "bucket_name" {
  default = "my-bucket"
}

variable "service_account_name" {
  default = "my-service-account"
}

variable "dataflow_job_name" {
  default = "my-dataflow-job"
}

variable "dataflow_template_gcs_path" {
  default = "gs://my-bucket/my-template"
}

resource "google_storage_bucket" "staging_bucket" {
  name     = var.bucket_name
  location = var.region
}

resource "google_service_account" "dataflow_service_account" {
  account_id = var.service_account_name
}

resource "google_service_account_key" "dataflow_service_account_key" {
  service_account_id = google_service_account.dataflow_service_account.id
}

resource "google_project_iam_member" "dataflow_service_account_iam_member" {
  project = var.project
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow_service_account.email}"
}

resource "google_dataflow_flex_template" "dataflow_job" {
  provider                = google
  project                 = var.project
  region                  = var.region
  template_gcs_path       = var.dataflow_template_gcs_path
  service_account_email   = google_service_account.dataflow_service_account.email
  staging_location        = "gs://${google_storage_bucket.staging_bucket.name}/staging"
  container_spec_gcs_path = "gs://${google_storage_bucket.staging_bucket.name}/container-spec"
  parameters = {
    param1 = "value1"
    param2 = "value2"
  }
}

resource "google_storage_bucket_object" "dataflow_template" {
  name   = "my-template"
  bucket = google_storage_bucket.staging_bucket.name
  source = file("${path.module}/my-template")
}

resource "google_storage_bucket_object" "container_spec" {
  name   = "container-spec"
  bucket = google_storage_bucket.staging_bucket.name
  source = file("${path.module}/container-spec")
}