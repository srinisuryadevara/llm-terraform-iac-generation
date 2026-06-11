terraform {
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.bucket_name
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "europe-west1"
}

variable "bucket_name" {
  type        = string
  sensitive   = true
}

variable "storage_class" {
  type        = string
  default     = "REGIONAL"
}

variable "lifecycle_rule_age" {
  type        = number
  default     = 365
}

locals {
  bucket_config = {
    project     = var.project_id
    location    = var.region
    storage_class = var.storage_class
  }
}

resource "google_storage_bucket" "private_bucket" {
  name     = "${var.project_id}-private-bucket"
  location = var.region
  storage_class = var.storage_class

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = var.lifecycle_rule_age
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_binding" "private_bucket" {
  bucket = google_storage_bucket.private_bucket.name
  role   = "roles/storage.objectViewer"
  members = [
    "serviceAccount:${var.project_id}@appspot.gserviceaccount.com",
  ]
}