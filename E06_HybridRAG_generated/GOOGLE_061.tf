terraform {
  required_version = ">= 1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.57"
    }
  }
  backend "gcs" {
    prefix  = "terraform/state"
    bucket  = var.bucket_name
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
}

provider "google-beta" {
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

variable "network" {
  type        = string
  default     = "default"
}

variable "ip_cidr_range" {
  type        = string
  default     = "10.9.0.0/28"
}

variable "memorystore_tier" {
  type        = string
  default     = "BASIC"
}

locals {
  config = {
    project     = var.project_id
    region      = var.region
    network     = var.network
    ip_cidr_range = var.ip_cidr_range
    memorystore_tier = var.memorystore_tier
  }
}

resource "google_vpc" "private_vpc" {
  project       = var.project_id
  name          = "private-vpc"
  auto_create_subnetworks = false
}

resource "google_subnetwork" "private_subnet" {
  project       = var.project_id
  name          = "private-subnet"
  ip_cidr_range = var.ip_cidr_range
  network       = google_vpc.private_vpc.id
  region        = var.region
}

resource "google_redis_instance" "cache" {
  name                    = "redis"
  memory_size_gb          = 1
  project                 = var.project_id
  location_id             = "${var.region}-c"
  tier                    = local.config.memorystore_tier
  authorized_network      = google_vpc.private_vpc.id
}

output "memorystore_host" {
  value = google_redis_instance.cache.host
}