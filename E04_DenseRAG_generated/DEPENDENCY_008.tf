# VARIABLES
variable "project" {}
variable "region" {
  default = "us-central1"
}
variable "service_name" {}
variable "container_image" {}
variable "container_port" {}
variable "max_instances" {}

# PROVIDERS
provider "google" {
  version = "~> 4.0"
  project = var.project
  region  = var.region
}

# RESOURCES
resource "google_service_account" "cloud_run_service_account" {
  account_id = "cloud-run-service-account"
}

resource "google_cloud_run_service" "main" {
  name     = var.service_name
  location = var.region

  template {
    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" = "default"
        "run.googleapis.com/vpc-access-egress" = "all-traffic"
        "autoscaling.knative.dev/maxScale"     = var.max_instances
      }
    }

    spec {
      service_account_name  = google_service_account.cloud_run_service_account.email
      container_concurrency = 80
      containers {
        image = var.container_image
        ports {
          container_port = var.container_port
        }
      }
    }
  }
  metadata {
    annotations = {
    }
  }
}

resource "google_cloud_run_service_iam_policy" "policy" {
  location = google_cloud_run_service.main.location
  project  = google_cloud_run_service.main.project
  service  = google_cloud_run_service.main.name

  policy_data = google_iam_policy.policy.policy_data
}

resource "google_iam_policy" "policy" {
  name        = "cloud-run-policy"
  description = "Cloud Run policy"

  policy_data = <<EOT
{
  "version": 3,
  "bindings": [
    {
      "role": "roles/run.invoker",
      "members": [
        "allUsers"
      ]
    }
  ]
}
EOT
}