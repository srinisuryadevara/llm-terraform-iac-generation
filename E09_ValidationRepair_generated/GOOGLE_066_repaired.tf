# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Define input variables
variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  sensitive   = true
}

variable "service_account_email" {
  type        = string
  sensitive   = true
}

# Create IAM bindings for the service account
resource "google_project_iam_binding" "service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
  labels = {
    environment = "production"
    application = "service-account"
  }
}

resource "google_project_iam_binding" "service_account_token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
  labels = {
    environment = "production"
    application = "service-account"
  }
}

resource "google_project_iam_binding" "logging_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
  labels = {
    environment = "production"
    application = "service-account"
  }
}

resource "google_project_iam_binding" "monitoring_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
  labels = {
    environment = "production"
    application = "service-account"
  }
}

resource "google_project_iam_binding" "storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
  labels = {
    environment = "production"
    application = "service-account"
  }
}

# Add missing resource: google_project_iam_binding for "roles/iam.serviceAccountKeyAdmin"
resource "google_project_iam_binding" "service_account_key_admin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountKeyAdmin"
  members = [
    "serviceAccount:${var.service_account_email}",
  ]
  labels = {
    environment = "production"
    application = "service-account"
  }
}

# Output key resource attributes
output "service_account_user_binding_id" {
  value = google_project_iam_binding.service_account_user.id
}

output "service_account_token_creator_binding_id" {
  value = google_project_iam_binding.service_account_token_creator.id
}

output "logging_log_writer_binding_id" {
  value = google_project_iam_binding.logging_log_writer.id
}

output "monitoring_metric_writer_binding_id" {
  value = google_project_iam_binding.monitoring_metric_writer.id
}

output "storage_object_viewer_binding_id" {
  value = google_project_iam_binding.storage_object_viewer.id
}

output "service_account_key_admin_binding_id" {
  value = google_project_iam_binding.service_account_key_admin.id
}