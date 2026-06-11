locals {
  project         = "larkworthy-tester"
  location        = "EU"
  region          = "europe-west1"
  base_image_name = "oryd/oathkeeper"
  base_image_tag  = "v0.37.1"
}

terraform {
  backend "gcs" {
    prefix = "ORY_Oathkeeper/state"
    bucket = "terraform-larkworthy"
  }
}

provider "google" {
  project = local.project
  region  = local.region
}

# Create service account to run service with no permissions
resource "google_service_account" "oathkeeper" {
  account_id   = "oathkeeper"
  display_name = "oathkeeper"
}

# Create Cloud Run service
resource "google_cloud_run_service" "oathkeeper" {
  name     = "oathkeeper-service"
  location = local.region

  template {
    spec {
      service_account_name = google_service_account.oathkeeper.email
      container_concurrency = 80
      containers {
        image = "${local.base_image_name}:${local.base_image_tag}"
        ports {
          container_port = 8080
        }
      }
    }
  }
}

# Policy to allow public access to Cloud Run endpoint
data "google_iam_policy" "noauth" {
  binding {
    role    = "roles/run.invoker"
    members = ["allUsers"]
  }
}

# Allow public access to ORY Oathkeeper
resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.oathkeeper.location
  project     = google_cloud_run_service.oathkeeper.project
  service     = google_cloud_run_service.oathkeeper.name
  policy_data = data.google_iam_policy.noauth.policy_data
}