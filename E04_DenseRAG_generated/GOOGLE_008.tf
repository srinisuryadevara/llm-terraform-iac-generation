terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = "terraform-gcp-bucket-tester" // Must be pre-provisioned
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
}

variable "project_id" {}
variable "region" {
  default = "us-central1"
}

variable "bucket_name" {}

resource "google_storage_bucket" "uniform_bucket_access" {
  name     = var.bucket_name
  location = var.region
  uniform_bucket_level_access = true
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_policy" "private_policy" {
  bucket = google_storage_bucket.uniform_bucket_access.name
  policy_data = data.google_iam_policy.private.policy_data
}

data "google_iam_policy" "private" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com",
    ]
  }
}