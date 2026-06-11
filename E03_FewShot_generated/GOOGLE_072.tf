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
  name        = "dataflow-policy"
  description = "Policy for Dataflow service account"

  policy_data = jsonencode({
    "bindings" : [
      {
        "role" : "roles/dataflow.worker"
        "members" : ["serviceAccount:${google_service_account.dataflow_service_account.email}"]
      },
      {
        "role" : "roles/dataflow.runner"
        "members" : ["serviceAccount:${google_service_account.dataflow_service_account.email}"]
      }
    ]
  })
}

resource "google_iam_policy" "dataflow_staging_policy" {
  name        = "dataflow-staging-policy"
  description = "Policy for Dataflow staging bucket"

  policy_data = jsonencode({
    "bindings" : [
      {
        "role" : "roles/storage.objectCreator"
        "members" : ["serviceAccount:${google_service_account.dataflow_service_account.email}"]
      },
      {
        "role" : "roles/storage.objectViewer"
        "members" : ["serviceAccount:${google_service_account.dataflow_service_account.email}"]
      }
    ]
  })
}

resource "google_dataflow_flex_template_run" "example" {
  provider                = google
  project                 = var.project_id
  region                  = var.region
  template_gcs_path       = "gs://${google_storage_bucket.dataflow_staging.name}/template"
  parameters              = {
    "input" : "gs://${google_storage_bucket.dataflow_staging.name}/input"
    "output" : "gs://${google_storage_bucket.dataflow_staging.name}/output"
  }
  service_account_email   = google_service_account.dataflow_service_account.email
  container_spec_gcs_path = "gs://${google_storage_bucket.dataflow_staging.name}/container-spec"
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}