provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "secure_bucket" {
  name                        = var.bucket_name
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
  storage_class               = var.storage_class
  versioning {
    enabled = true
  }
  encryption {
    default_kms_key_name = var.kms_key_name
  }
  lifecycle_rule {
    condition {
      age = var.lifecycle_age
    }
    action {
      type = "Delete"
    }
  }
  labels = {
    environment = var.environment
    project     = var.project_id
  }
}

resource "google_storage_bucket_iam_policy" "secure_bucket_policy" {
  bucket      = google_storage_bucket.secure_bucket.name
  policy_data = data.google_iam_policy.secure_bucket_policy.policy_data
}

data "google_iam_policy" "secure_bucket_policy" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "serviceAccount:${var.service_account_email}",
    ]
  }
}

variable "project_id" {
  type        = string
  description = "The ID of the project"
}

variable "region" {
  type        = string
  description = "The region of the bucket"
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket"
}

variable "storage_class" {
  type        = string
  description = "The storage class of the bucket"
}

variable "kms_key_name" {
  type        = string
  description = "The name of the KMS key"
}

variable "lifecycle_age" {
  type        = number
  description = "The age of the objects to delete"
}

variable "environment" {
  type        = string
  description = "The environment of the bucket"
}

variable "service_account_email" {
  type        = string
  description = "The email of the service account"
}