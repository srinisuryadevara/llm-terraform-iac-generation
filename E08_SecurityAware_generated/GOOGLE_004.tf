provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "service_name" {
  type        = string
  description = "Cloud Run service name"
}

variable "traffic_split" {
  type        = map(number)
  description = "Traffic split configuration"
}

variable "iam_members" {
  type        = list(string)
  description = "List of IAM members to bind to the service"
}

variable "iam_roles" {
  type        = list(string)
  description = "List of IAM roles to bind to the service"
}

resource "google_cloud_run_service" "example" {
  name     = var.service_name
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/${var.service_name}"
      }
    }
  }

  traffic {
    percent         = var.traffic_split["percent"]
    latest_revision = true
  }

  traffic {
    percent         = 100 - var.traffic_split["percent"]
    revision_name   = "example-revision"
  }
}

resource "google_cloud_run_service_iam_binding" "example" {
  location = google_cloud_run_service.example.location
  service  = google_cloud_run_service.example.name
  role     = var.iam_roles[0]
  members  = var.iam_members
}

resource "google_cloud_run_service_iam_policy" "example" {
  location = google_cloud_run_service.example.location
  service  = google_cloud_run_service.example.name
  policy   = data.google_iam_policy.example.policy
}

data "google_iam_policy" "example" {
  binding {
    role = var.iam_roles[0]
    members = var.iam_members
  }
}

resource "google_kms_key_ring" "example" {
  name     = "example-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "example" {
  name     = "example-key"
  key_ring = google_kms_key_ring.example.id
}

resource "google_kms_key_ring_iam_policy" "example" {
  key_ring_id = google_kms_key_ring.example.id
  policy      = data.google_iam_policy.example.policy
}

output "service_url" {
  value       = google_cloud_run_service.example.status[0].url
  description = "URL of the Cloud Run service"
}

output "service_name" {
  value       = google_cloud_run_service.example.name
  description = "Name of the Cloud Run service"
}

output "project_id" {
  value       = var.project_id
  description = "GCP project ID"
}

output "region" {
  value       = var.region
  description = "GCP region"
}