locals {
  project           = var.project
  location          = var.location
  region            = var.region
  service_name      = var.service_name
  base_image_name   = var.base_image_name
  base_image_tag    = var.base_image_tag
  upstream_url      = var.upstream_url
  authorized_domain = var.authorized_domain
  oauth_client_id   = var.oauth_client_id
  service_url       = "https://${var.service_name}-${var.region}.run.app"
}

variable "project" {
  type        = string
  sensitive   = true
}

variable "location" {
  type        = string
  default     = "EU"
}

variable "region" {
  type        = string
  default     = "europe-west1"
}

variable "service_name" {
  type        = string
}

variable "base_image_name" {
  type        = string
}

variable "base_image_tag" {
  type        = string
}

variable "upstream_url" {
  type        = string
}

variable "authorized_domain" {
  type        = string
}

variable "oauth_client_id" {
  type        = string
  sensitive   = true
}

terraform {
  backend "gcs" {
    prefix = "cloudrun/state"
    bucket = "terraform-cloudrun"
  }
}

provider "google" {
  project = local.project
  region  = local.region
}

resource "google_service_account" "cloudrun" {
  account_id   = "cloudrun"
  display_name = "cloudrun"
}

resource "google_project_iam_member" "cloudrun_invoker" {
  project = local.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cloudrun.email}"
}

resource "google_cloud_run_service" "cloudrun" {
  name     = local.service_name
  location = local.region

  template {
    spec {
      service_account_name = google_service_account.cloudrun.email
      containers {
        image = "${local.base_image_name}:${local.base_image_tag}"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "cloudrun_invoker" {
  location = google_cloud_run_service.cloudrun.location
  service  = google_cloud_run_service.cloudrun.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}