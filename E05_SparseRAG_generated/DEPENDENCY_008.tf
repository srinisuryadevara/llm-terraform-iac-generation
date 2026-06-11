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
  description = "The ID of the project to apply any changes to"
}

variable "location" {
  type        = string
  description = "The location to deploy the service to"
}

variable "region" {
  type        = string
  description = "The region to deploy the service to"
}

variable "service_name" {
  type        = string
  description = "The name of the service to deploy"
}

variable "base_image_name" {
  type        = string
  description = "The name of the base image to use"
}

variable "base_image_tag" {
  type        = string
  description = "The tag of the base image to use"
}

variable "upstream_url" {
  type        = string
  description = "The URL of the upstream service"
}

variable "authorized_domain" {
  type        = string
  description = "The authorized domain for the service"
}

variable "oauth_client_id" {
  type        = string
  description = "The OAuth client ID for the service"
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
  display_name = "Cloud Run Service Account"
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
      containers {
        image = "${local.base_image_name}:${local.base_image_tag}"
      }
      service_account_name = google_service_account.cloudrun.email
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