terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = "terraform-larkworthy-tester" // Must be pre-provisioned
  }
}

provider "google" {
  project     = "larkworthy-tester"
  region      = "europe-west1"
}

locals {
  project = "larkworthy-tester"
  bucket_name = "${local.project}_storage"
  location = "EU"
}

resource "google_storage_bucket" "storage" {
  name               = local.bucket_name
  location           = local.location
  uniform_bucket_level_access = true
  force_destroy      = true
}

resource "google_storage_bucket_iam_policy" "storage" {
  bucket      = google_storage_bucket.storage.name
  policy_data = data.google_iam_policy.storage.policy_data
}

data "google_iam_policy" "storage" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${local.project}@appspot.gserviceaccount.com",
    ]
  }
  binding {
    role = "roles/storage.objectCreator"
    members = [
      "serviceAccount:${local.project}@appspot.gserviceaccount.com",
    ]
  }
  binding {
    role = "roles/storage.objectAdmin"
    members = [
      "user:${local.project}@larkworthy-tester.iam.gserviceaccount.com",
    ]
  }
}