variable "project" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "service_account_email" {
  type        = string
  description = "Service account email"
}

variable "cloud_run_service_name" {
  type        = string
  description = "Cloud Run service name"
}

variable "cloud_run_container_image" {
  type        = string
  description = "Cloud Run container image"
}

variable "cloud_run_container_port" {
  type        = number
  description = "Cloud Run container port"
}

variable "source_cidr_blocks" {
  type        = list(string)
  description = "Source CIDR blocks for ingress"
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_service_account" "cloud_run_service_account" {
  account_id = "cloud-run-service-account"
  description = "Service account for Cloud Run service"
}

resource "google_service_account_key" "cloud_run_service_account_key" {
  service_account_id = google_service_account.cloud_run_service_account.id
}

resource "google_cloud_run_service" "cloud_run_service" {
  name     = var.cloud_run_service_name
  location = var.region
  template {
    spec {
      containers {
        image = var.cloud_run_container_image
        ports {
          container_port = var.cloud_run_container_port
        }
      }
      service_account_name = google_service_account.cloud_run_service_account.email
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
  depends_on = [google_service_account.cloud_run_service_account]
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_iam_policy" "cloud_run_service_policy" {
  name        = "cloud-run-service-policy"
  description = "Policy for Cloud Run service"

  policy_data = jsonencode({
    "version" : "2012-10-17",
    "statement" : [
      {
        "sid" : "AllowCloudRunService",
        "effect" : "Allow",
        "action" : [
          "run.services.get",
          "run.services.update",
          "run.services.delete",
        ],
        "resource" : "projects/${var.project}/locations/${var.region}/services/${var.cloud_run_service_name}",
      },
    ]
  })
}

resource "google_iam_role" "cloud_run_service_role" {
  name        = "cloud-run-service-role"
  description = "Role for Cloud Run service"

  permissions = [
    "run.services.get",
    "run.services.update",
    "run.services.delete",
  ]
}

resource "google_iam_role_policy_attachment" "cloud_run_service_policy_attachment" {
  role       = google_iam_role.cloud_run_service_role.name
  policy_arn = google_iam_policy.cloud_run_service_policy.arn
}

resource "google_cloud_run_service_iam_policy" "cloud_run_service_iam_policy" {
  location = var.region
  project  = var.project
  service  = var.cloud_run_service_name

  policy_data = jsonencode({
    "version" : "2012-10-17",
    "statement" : [
      {
        "sid" : "AllowCloudRunService",
        "effect" : "Allow",
        "action" : [
          "run.services.get",
          "run.services.update",
          "run.services.delete",
        ],
        "resource" : "projects/${var.project}/locations/${var.region}/services/${var.cloud_run_service_name}",
      },
    ]
  })
}

resource "google_compute_firewall" "cloud_run_firewall" {
  name    = "cloud-run-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = [var.cloud_run_container_port]
  }

  source_ranges = var.source_cidr_blocks
  target_tags   = ["cloud-run-service"]
}

resource "google_compute_network" "cloud_run_network" {
  name                    = "cloud-run-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "cloud_run_subnetwork" {
  name          = "cloud-run-subnetwork"
  ip_cidr_range = "10.0.0.0/16"
  network       = google_compute_network.cloud_run_network.id
  region        = var.region
}

resource "google_kms_key_ring" "cloud_run_key_ring" {
  name     = "cloud-run-key-ring"
  location = var.region
}

resource "google_kms_crypto_key" "cloud_run_crypto_key" {
  name     = "cloud-run-crypto-key"
  key_ring = google_kms_key_ring.cloud_run_key_ring.id
}

resource "google_kms_crypto_key_version" "cloud_run_crypto_key_version" {
  crypto_key = google_kms_crypto_key.cloud_run_crypto_key.id
}

resource "google_storage_bucket" "cloud_run_bucket" {
  name     = "cloud-run-bucket"
  location = var.region
  storage_class = "REGIONAL"
  force_destroy = true

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.cloud_run_crypto_key.id
  }
}

resource "google_storage_bucket_iam_policy" "cloud_run_bucket_policy" {
  bucket = google_storage_bucket.cloud_run_bucket.name
  policy_data = jsonencode({
    "version" : "2012-10-17",
    "statement" : [
      {
        "sid" : "AllowCloudRunService",
        "effect" : "Allow",
        "action" : [
          "storage.objects.get",
          "storage.objects.list",
        ],
        "resource" : "projects/${var.project}/buckets/${google_storage_bucket.cloud_run_bucket.name}",
      },
    ]
  })
}