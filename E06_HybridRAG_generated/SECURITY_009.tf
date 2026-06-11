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
  default     = "us-central1"
}

variable "bucket_name" {
  type        = string
  sensitive   = true
}

variable "bucket_location" {
  type        = string
  default     = "US"
}

variable "lifecycle_rule_age" {
  type        = number
  default     = 30
}

locals {
  bucket_config = {
    name               = var.bucket_name
    location           = var.bucket_location
    force_destroy      = true
    uniform_bucket_level_access = {
      enabled = true
    }
    lifecycle_rule = [
      {
        action = {
          type = "Delete"
        }
        condition = {
          age = var.lifecycle_rule_age
        }
      }
    ]
  }
}

resource "google_storage_bucket" "private_bucket" {
  name               = local.bucket_config.name
  location           = local.bucket_config.location
  force_destroy      = local.bucket_config.force_destroy
  uniform_bucket_level_access = {
    enabled = local.bucket_config.uniform_bucket_level_access.enabled
  }
  lifecycle_rule {
    action {
      type = local.bucket_config.lifecycle_rule[0].action.type
    }
    condition {
      age = local.bucket_config.lifecycle_rule[0].condition.age
    }
  }
}