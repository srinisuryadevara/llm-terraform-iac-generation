provider "google" {
  project = var.project_id
  region  = var.region
}

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

variable "roles" {
  type        = list(string)
  default     = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer"
  ]
  sensitive   = true
}

resource "google_project_iam_binding" "service_account" {
  project = var.project_id
  role    = var.roles[0]

  members = [
    "serviceAccount:${var.service_account_email}",
  ]

  labels = {
    environment = "dev"
    application = "gcp-iam-service-account-bindings"
  }
}

resource "google_project_iam_binding" "service_account_monitoring" {
  project = var.project_id
  role    = var.roles[1]

  members = [
    "serviceAccount:${var.service_account_email}",
  ]

  labels = {
    environment = "dev"
    application = "gcp-iam-service-account-bindings"
  }
}

resource "google_project_iam_binding" "service_account_stackdriver" {
  project = var.project_id
  role    = var.roles[2]

  members = [
    "serviceAccount:${var.service_account_email}",
  ]

  labels = {
    environment = "dev"
    application = "gcp-iam-service-account-bindings"
  }
}

output "service_account_binding_id" {
  value = google_project_iam_binding.service_account.id
}

output "service_account_monitoring_binding_id" {
  value = google_project_iam_binding.service_account_monitoring.id
}

output "service_account_stackdriver_binding_id" {
  value = google_project_iam_binding.service_account_stackdriver.id
}

output "service_account_binding_members" {
  value = google_project_iam_binding.service_account.members
}

output "service_account_monitoring_binding_members" {
  value = google_project_iam_binding.service_account_monitoring.members
}

output "service_account_stackdriver_binding_members" {
  value = google_project_iam_binding.service_account_stackdriver.members
}