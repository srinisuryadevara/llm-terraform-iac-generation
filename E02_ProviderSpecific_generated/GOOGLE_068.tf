provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "staging_bucket" {
  name     = "${var.project_id}-dataflow-staging-bucket"
  location = var.region
  storage_class = "REGIONAL"
}

resource "google_service_account" "dataflow_service_account" {
  account_id = "dataflow-service-account"
}

resource "google_service_account_key" "dataflow_service_account_key" {
  service_account_id = google_service_account.dataflow_service_account.id
}

resource "google_iam_role" "dataflow_role" {
  name        = "dataflow-role"
  title       = "Dataflow Role"
  description = "Role for Dataflow job"
}

resource "google_iam_role_binding" "dataflow_binding" {
  role = google_iam_role.dataflow_role.id
  members = [
    "serviceAccount:${google_service_account.dataflow_service_account.email}",
  ]
}

resource "google_iam_project_iam_binding" "dataflow_project_binding" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  members = [
    "serviceAccount:${google_service_account.dataflow_service_account.email}",
  ]
}

resource "google_dataflow_job" "example_job" {
  name                = "example-dataflow-job"
  template_gcs_path   = "gs://${google_storage_bucket.staging_bucket.name}/template"
  temp_gcs_location   = "gs://${google_storage_bucket.staging_bucket.name}/temp"
  service_account_email = google_service_account.dataflow_service_account.email
  parameters = {
    foo = "bar"
  }
  depends_on = [google_iam_role_binding.dataflow_binding, google_iam_project_iam_binding.dataflow_project_binding]
}